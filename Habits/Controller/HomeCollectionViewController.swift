//
//  HomeCollectionViewController.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit



class HomeCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item.ID>
    
    enum ViewModel{
        enum Section: Hashable{
            case leaderboard
            case followedUsers
        }
        
        enum Item: Identifiable, Equatable{
            case leaderboardHabit(name: String, leadingUserRanking: String?, secondaryUserRanking: String?)
            case followedUser(_ user: User, message: String)
            
            var id: String{
                switch self{
                case .leaderboardHabit(name: let name, _, _):
                    return "leaderboardHabit: \(name)"
                case .followedUser(let user, message: let message):
                    return "followedUser: \(user.name)"
                }
            }
            
            static func ==(_ lhs: Item, _ rhs: Item) -> Bool{
                return lhs.id == rhs.id
                
            }
        }
    }
    
    struct Model{
        var usersByID = [String: User]()
        var habitsByName = [String: Habit]()
        var userStatistics = [UserStatistics]()
        var habitStatistics = [HabitStatistics]()
        
        
        var currentUser: User{
            Settings.shared.currentUser
        }
        
        var users: [User]{
            return Array(usersByID.values)
        }
        
        var habits: [Habit]{
            return Array(habitsByName.values)
        }
        
        var followedUser: [User]{
            return Array(usersByID.filter{ Settings.shared.followedUserIDs.contains($0.key)}.values)
        }
        
        var favoriteHabits: [Habit]{
            return Settings.shared.favoriteHabits
        }
        
        var nonFavoriteHabits: [Habit]{
            return habits.filter{ !favoriteHabits.contains($0) }
        }
        
    }
    
    var model = Model()
    var items: [ViewModel.Item] = []
    var dataSource: DataSourceType!
    
    var userRequestTask: Task<Void, Never>? = nil
    var habitRequestTask: Task<Void, Never>? = nil
    var combinedStatisticsRequestTask: Task<Void, Never>? = nil
    
    var updateTimer: Timer?
    
    static let formatter: NumberFormatter = {
        var f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()
    
    deinit{
        userRequestTask?.cancel()
        habitRequestTask?.cancel()
        combinedStatisticsRequestTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userRequestTask = Task{
            if let users = try? await UserRequest().send(){
                model.usersByID = users
            }else{
                model.usersByID = [:]
            }
            userRequestTask = nil
        }
        
        habitRequestTask = Task{
            if let habits = try? await HabitRequest().send(){
                model.habitsByName = habits
            }else{
                model.habitsByName = [:]
            }
            
            habitRequestTask = nil
        }
        
        update()
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        update()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
            self.update()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func update(){
        combinedStatisticsRequestTask?.cancel()
        combinedStatisticsRequestTask = Task{
            if let combinedStatistics = try? await CombinedStatsRequest().send(){
                self.model.userStatistics = combinedStatistics.userStatistics
                self.model.habitStatistics = combinedStatistics.habitStatistics
            }else{
                self.model.userStatistics = []
                self.model.habitStatistics = []
            }
            
            self.updateCollectionView()
            combinedStatisticsRequestTask = nil
        }
    }
    
    func ordinalString(from number: Int) -> String{
        return HomeCollectionViewController.formatter.string(from: NSNumber(integerLiteral: number + 1))!
    }
    
    func loggedHabitNames(for user: User) -> Set<String>{
        var names = [String]()
        
        if let stats = model.userStatistics.first(where: {$0.user == user}){
            names = stats.habitCounts.map{$0.habit.name}
        }
        
        return Set(names)
    }
    
    func updateCollectionView(){
        var sectionIDs = [ViewModel.Section]()
        let leaderboardItems = model.habitStatistics.filter { statistic in
            return model.favoriteHabits.contains{ $0.name == statistic.habit.name}
        }
            .sorted{ $0.habit.name < $1.habit.name}
            .reduce(into: [ViewModel.Item]()) { partialResult, statistic in
                // Rank the users counts from highest to lowest
                let rankedUserCounts = statistic.userCounts.sorted(by: {$0.count > $1.count})
                let myCountIndex = rankedUserCounts.firstIndex(where: {$0.user.id == model.currentUser.id})
                
                func userRankingString(from userCount: UserCount) -> String{
                    var name = userCount.user.name
                    var ranking = ""
                    
                    if userCount.user.id == model.currentUser.id{
                        name = "You"
                        ranking = "(\(ordinalString(from: myCountIndex!)))"
                    }
                    
                    return "\(name) \(userCount.count) " + ranking
                }
                
                let leadingRanking: String?
                let secondaryRanking: String?
                
                switch rankedUserCounts.count{
                case 0:
                    leadingRanking = "Nobody yet!"
                    secondaryRanking = nil
                    
                case 1:
                    let onlyCount = rankedUserCounts.first!
                    leadingRanking = userRankingString(from: onlyCount)
                    secondaryRanking = nil
                
                default:
                    leadingRanking = userRankingString(from: rankedUserCounts[0])
                    
                    if let myCountIndex = myCountIndex , myCountIndex != rankedUserCounts.startIndex{
                       
                        secondaryRanking = userRankingString(from: rankedUserCounts[myCountIndex])
                    }else{
                        secondaryRanking = userRankingString(from: rankedUserCounts[1])
                    }
           
                }
                
                partialResult.append(.leaderboardHabit(name: statistic.habit.name, leadingUserRanking: leadingRanking, secondaryUserRanking: secondaryRanking))
                
               
                
            }
        
        sectionIDs.append(.leaderboard)
        
        var followedUserItems = [ViewModel.Item]()
//        Get the current user's logged habits an extract the favorites
        let currentUserLoggedHabits = loggedHabitNames(for: model.currentUser)
        let favoriteLoggedHabits = Set(model.favoriteHabits.map(\.name)).intersection(currentUserLoggedHabits)
        
        for followedUser in model.followedUser.sorted(by: {$0.name < $1.name}) {
            let message: String
            
            let followedUserLoggedHabits = loggedHabitNames(for: followedUser)
            let commonLoggedHabits = followedUserLoggedHabits.intersection(currentUserLoggedHabits)
            
            if commonLoggedHabits.count > 0{
//                Pick the habit to focus
                let habitName: String
                let commonFavoriteLoggedHabits = commonLoggedHabits.intersection(favoriteLoggedHabits)
                
                if commonFavoriteLoggedHabits.count > 0{
                    habitName = commonFavoriteLoggedHabits.sorted().first!
                }else{
                    habitName = commonLoggedHabits.sorted().first!
                }
                
                let habitStats = model.habitStatistics.first(where: {$0.habit.name == habitName})!
                
                let rankedUserCounts = habitStats.userCounts.sorted(by: {$0.count > $1.count})
                let currentUserRanking = rankedUserCounts.firstIndex(where: {$0.user == model.currentUser})!
                let followedUserRanking = rankedUserCounts.firstIndex(where: {$0.user == followedUser})!
                
                if currentUserRanking < followedUserRanking{
                    message = "Currently #\(ordinalString(from: followedUserRanking)), behind you #\(ordinalString(from: currentUserRanking)) in \(habitName). \nSend them a friendly reminder!"
                }else if currentUserRanking > followedUserRanking{
                    message = "Currently #\(ordinalString(from: followedUserRanking)), ahead you #\(ordinalString(from: currentUserRanking)) in \(habitName). \nYou might catch up with a little extra effort!"
                }else{
                    message = "You're tied at \(ordinalString(from: followedUserRanking)) in \(habitName)! Now's your chance to pull ahead"
                }
 
            }else if followedUserLoggedHabits.count > 0{
                let habitName = followedUserLoggedHabits.sorted().first!
                
                let habitStats = model.habitStatistics.first(where: {$0.habit.name == habitName})!
                let rankedUserCounts = habitStats.userCounts.sorted(by: {$0.count > $1.count})
                let followedUserRanking = rankedUserCounts.firstIndex(where: {$0.user == followedUser})!
                
                message = "Currently #\(ordinalString(from: followedUserRanking)) in\(habitName). \nMay be you should give this habit a look!"
            }else{
                message = "This user doesn't seem to have done much yet. Check in to see if they need any help getting started"
            }
            
            followedUserItems.append(.followedUser(followedUser, message: message))
        }
        
        sectionIDs.append(.followedUsers)
       
        var itemsBySection = [ViewModel.Section.leaderboard: leaderboardItems.map(\.id)]
        itemsBySection[ViewModel.Section.followedUsers] = followedUserItems.map(\.id)
        
        items = leaderboardItems
        items += followedUserItems
        
        dataSource.applySnapshotUsing(sectionIDs: sectionIDs, itemBySections: itemsBySection)
        
        
    }
    
    func createDataSource() -> DataSourceType{
        let habitNib = UINib(nibName: "LeaderboardHabitCollectionViewCell", bundle: Bundle(for: LeaderBoardHabitCollectionViewCell.self))
        
        let habitRegistration = UICollectionView.CellRegistration<LeaderBoardHabitCollectionViewCell, ViewModel.Item.ID>(cellNib: habitNib) {[weak self] cell, indexPath, itemIdentifier in
            
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}), case let .leaderboardHabit(name: name, leadingUserRanking, secondaryUserRanking) = item else{
                return
            }
            
            cell.habitName.text = name
            cell.leaderLabel.text = leadingUserRanking
            cell.secondaryLabel.text = secondaryUserRanking
        }
        
        let userNib = UINib(nibName: "FollowedCollectionViewCell", bundle: Bundle(for: FollowedCollectionViewCell.self))
        let userResigtration = UICollectionView.CellRegistration<FollowedCollectionViewCell, ViewModel.Item.ID>(cellNib: userNib) {[weak self] cell, indexPath, itemIdentifier in
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}) , case let .followedUser(user, message) = item  else{
                return
            }
            
            cell.userNameLabel.text = user.name
            cell.messageLabel.text = message
        }
        
        let dataSource =  DataSourceType(collectionView: collectionView) {[weak self] collectionView, indexPath, itemIdentifier in
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}) else {return nil}
            switch item{
            case .leaderboardHabit:
               return collectionView.dequeueConfiguredReusableCell(using: habitRegistration, for: indexPath, item: itemIdentifier)
            case .followedUser:
                return collectionView.dequeueConfiguredReusableCell(using: userResigtration, for: indexPath, item: itemIdentifier)
            }
        }
        
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout{
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            
            switch self.dataSource.snapshot().sectionIdentifiers[sectionIndex]{
                
            case .leaderboard:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.3))
                let habitFavoriteItem = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .fractionalWidth(0.77))
                let habitFavoriteGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: habitFavoriteItem, count: 3)
                habitFavoriteGroup.interItemSpacing = .fixed(10)
                
                let habitFavoriteSection = NSCollectionLayoutSection(group: habitFavoriteGroup)
                habitFavoriteSection.interGroupSpacing = 20
                habitFavoriteSection.orthogonalScrollingBehavior = .continuous
                habitFavoriteSection.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20)
                
                return habitFavoriteSection
            case .followedUsers:
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let userFollowedItem = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let userFollowedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [userFollowedItem])
                
                let userFollowedSection = NSCollectionLayoutSection(group: userFollowedGroup)

                return userFollowedSection
            }
        
        })
        
        return layout
        
        
    }
    
    
    
    
   
    
    
}
