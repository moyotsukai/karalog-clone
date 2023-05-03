//
//  FirebaseAPI.swift
//  Karalog
//
//  Created by 伊藤汰海 on 2023/04/30.
//

import Foundation
import FirebaseCore
import FirebaseFirestore


struct FirebaseAPI {
    
    static let shared = FirebaseAPI()
    var userID = UserDefaults.standard.string(forKey: "userID")
    var userRef: DocumentReference!
    var musicRef: CollectionReference!
    var listRef: CollectionReference!
    var wannaRef: CollectionReference!
    
    init() {
        
        userRef = Firestore.firestore().collection("user").document(userID!)
        musicRef = userRef.collection("musicList")
        listRef = userRef.collection("lists")
        wannaRef = userRef.collection("wannaList")
    }
    
    //musicListを取得
    func getMusic(completionHandler: @escaping ([MusicList]) -> Void) {
        
        musicRef.getDocuments() { (collection, err) in
            if let err = err {
                print("error getting music: \(err)")
                completionHandler([])
            }else{
                Manager.shared.musicList = []
                for document in collection!.documents {
                    do{
                        Manager.shared.musicList.append(try document.data(as: MusicList.self))
                        
                    }catch{
                        print(error)
                    }
                }
                completionHandler(Manager.shared.musicList)
            }
        }
    }
    
    //listsを取得
    func getlist(completionHandler: @escaping (Any) -> Void) {
        userRef.getDocument() { (document, err) in
            if let document = document, document.exists{
                Manager.shared.listOrder = document.data()!["listOrder"] as? [String] ?? []
                print("getting listOrder")
                
            } else {
                print("Error getting listOrder")
            }
            listRef.getDocuments() { (collection, err) in
                if let err = err {
                    print("error getting list: \(err)")
                    
                }else{
                    print("getting list")
                    Manager.shared.lists = []
                    for document in collection!.documents {
                        do{
                            Manager.shared.lists.append(try document.data(as: Lists.self))
                        }catch{
                            print(error)
                        }
                    }
                    var preList: [Lists] = []
                    
                    
                    for i in Manager.shared.listOrder {
                        
                        preList.append(Manager.shared.lists.first(where: {$0.id!.contains(i)})!)
                    }
                    Manager.shared.lists = Material.shared.initialListData
                    
                    
                    Manager.shared.lists += preList
                    
                    completionHandler(true)
                }
                
                
            }
        }
        
    }
    
    //wannaListを取得
    func getWanna(completionHandler: @escaping ([MusicList]) -> Void) {
        wannaRef.getDocuments { (collection, err) in
            var list: [MusicList] = []
            if let err = err {
                print("Error getting wanna list: \(String(describing: err))")
                completionHandler([])
            } else {
                for document in collection!.documents {
                    let name = document["musicName"] as! String
                    let artist = document["artistName"] as! String
                    let image = document["musicImage"] as! Data
                    let id = document.documentID
                    list.append(MusicList(musicName: name, artistName: artist, musicImage: image, favorite: false, lists: [], data: [], id: id))
                }
                completionHandler(list)
            }
        }
    }
    
    //musicListに追加
    func addMusic(musicName: String, artistName: String, musicImage: Data, time: String, score: Double, key: Int, model: String, comment: String) {
        let detailData = ["time": time, "score": score, "key": key, "model": model, "comment": comment] as [String : Any]
        musicRef.addDocument(data: [
            "musicName": musicName,
            "artistName": artistName,
            "musicImage": musicImage,
            "favorite": false,
            "lists": [],
            "data": [detailData]
        ]) { err in
            if let err = err {
                print("Error adding music: \(err)")
            }else{
                print("music added")
                Manager.shared.musicList.append(MusicList(musicName: musicName, artistName: artistName, musicImage: musicImage, favorite: false, lists: [], data: []))
            }
        }
    }
    
    //musicDataを追加
    func addMusicDetail(musicID: String, time: String, score: Double, key: Int, model: String, comment: String) {
        let indexPath = Manager.shared.musicList.firstIndex(where: {$0.id == musicID})!
        let d = [
            "time": time,
            "score": score,
            "key": key,
            "model": model,
            "comment": comment
        ] as [String : Any]
        musicRef.document(musicID).updateData([
            "data": FieldValue.arrayUnion([d])
        ]) {err in
            if let err = err {
                print("Error adding detail \(err)")
            }else{
                print("detail successfully added")
                Manager.shared.musicList[indexPath].data.append(MusicData(time: time, score: score, key: key, model: model, comment: comment))
            }
        }
    }
    
    //listを追加
    func addList(listName: String, listImage: Data) {
        let ref = listRef.addDocument(data: [
            "listName": listName,
            "listImage": listImage
        ]){err in
            if let err = err {
                print("Error adding list")
            }else{
                print("list successfully added")
                
            }
            
        }
        userRef.updateData([
            "listOrder": FieldValue.arrayUnion([ref.documentID])
        ])
        Manager.shared.lists.append(Lists(listName: listName, listImage: listImage, id: ref.documentID))
        Manager.shared.listOrder.append(ref.documentID)
    }
    
    //wannaListを追加
    func addWanna(musicName: String, artistName: String, musicImage: Data) {
        wannaRef.addDocument(data: [
            "musicName": musicName,
            "artistName": artistName,
            "musicImage": musicImage
        ]) {err in
            if let err = err {
                print("Error adding music: \(err)")
            }else{
                print("music successfully added")
            }
        }
    }
    
    //listに追加
    func addMusicToList(musicID: String, listID: String) {
        let indexPath = Manager.shared.musicList.firstIndex(where: {$0.id == musicID})!
        musicRef.document(musicID).updateData([
            "lists": FieldValue.arrayUnion([listID])
        ]) { err in
            if let err = err {
                print("Error adding music \(err)")
            }else{
                print("musicAdded")
                Manager.shared.musicList[indexPath].lists.append(listID)
            }
        }
    }
    
    //musicListを削除
    func deleteMusic(id: String, completionHandler: @escaping (Any) -> Void) {
        musicRef.document(id).delete() { err in
            if let err = err {
                print("error deleting music: \(err)")
            }else{
                print("music successfully deleted")
                Manager.shared.musicList.removeAll(where: {$0.id == id})
                completionHandler(true)
            }
            
        }
    }
    
    //musicDataを削除
    func deleteMusicDetail(musicID: String, data: MusicData, completionHandler: @escaping (Any) -> Void) {
        let indexPath = Manager.shared.musicList.firstIndex(where: {$0.id == musicID})!
        let d = ["comment": data.comment,
                 "key": data.key,
                 "model": data.model,
                 "score": data.score,
                 "time": data.time] as [String : Any]
        musicRef.document(musicID).updateData([
            "data": FieldValue.arrayRemove([d])
        ]){err in
            if let err = err {
                print("Error deleting detail: \(err)")
            }else{
                print("detail successfully deleted")
                
                Manager.shared.musicList[indexPath].data.removeAll(where: {$0.time == data.time})
                completionHandler(true)
            }
        }
    }
    
    //listを削除
    func deleteList(indexPath: IndexPath, completionHandler: @escaping (Any) -> Void) {
        let listID = Manager.shared.lists[indexPath.row].id!
        listRef.document(listID).delete() { err in
            if let err = err {
                print("error removing music: \(err)")
            }else{
                print("music successfully removed")
                userRef.updateData([
                    "listOrder": FieldValue.arrayRemove([listID])
                ]){err in
                    if let err = err {
                        print("Error deleting music order: \(err)")
                    }else{
                        print("music order successfully deleted")
                        Manager.shared.lists.remove(at: indexPath.row)
                        
                    }
                    completionHandler(true)
                }
            }
            
        }
    }
    
    //wannaListを削除
    func deleteWanna(wannaID: String) {
        wannaRef.document(wannaID).delete(){err in
            if let err = err {
                print("Error deleting detail: \(err)")
            }else{
                print("detail successfully deleted")
                
            }
        }
    }
    
    //listからmusicを削除
    func deleteMusicFromList(selectedID: String, listID: String, completionHandler: @escaping (Any) -> Void) {
        musicRef.document(selectedID).updateData([
            "lists": FieldValue.arrayRemove([listID])
        ]) { err in
            if let err = err {
                print("Error updating favorite: \(err)")
            } else {
                print("favorite successfully updated")
                
                let num = Manager.shared.musicList.firstIndex(where: {$0.id!.contains(selectedID)})
                Manager.shared.musicList.remove(at: num!)
                
                completionHandler(true)
            }
        }
    }
    
    //favoriteを更新
    func favoriteUpdate(id: String, favorite: Bool, completionHandler: @escaping (Any) -> Void) {
        if favorite == false {
            musicRef.document(id).updateData([
                "favorite": true
            ]){ err in
                if let err = err {
                    print("Error updating favorite: \(err)")
                } else {
                    print("favorite successfully updated")
                    
                    let num = Manager.shared.musicList.firstIndex(where: {$0.id!.contains(id)})
                    Manager.shared.musicList[num!].favorite = true
                    
                    completionHandler(true)
                }
            }
        } else {
            musicRef.document(id).updateData([
                "favorite": false
            ]){ err in
                if let err = err {
                    print("Error updating favorite: \(err)")
                } else {
                    print("favorite successfully updated")
                    
                    let num = Manager.shared.musicList.firstIndex(where: {$0.id!.contains(id)})
                    Manager.shared.musicList[num!].favorite = false
                   
                    completionHandler(true)
                }
            }
        }
    }
    
    //listOrderを更新
    func listOrderUpdate(listOrder: [String]) {
        userRef.updateData([
            "listOrder": listOrder
        ]) {err in
            if let err = err {
                print("Error updating list order: \(err)")
            }else{
                print("list order successfully updated")
                Manager.shared.listOrder = listOrder
            }
        }
    }
}
