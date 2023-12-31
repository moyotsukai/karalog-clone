//
//  SearchViewController.swift
//  Karalog
//
//  Created by 伊藤汰海 on 2023/03/24.
//

import UIKit
import Alamofire
import Dispatch
import Vision
import VisionKit

class SearchViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    
    var musicName: String!
    var artistName: String!
    var musicImage: String!
    
    //itunesの情報を取得
    let decoder: JSONDecoder = JSONDecoder()
    var musicInfoModel = [MusicInfoModel]() {
        didSet {
        }
    }
    
    var resultingText = ""
    var requests = [VNRequest]()
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupSearchBar()
//        setupVision()
        
        
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddMusic"{
            let nextView = segue.destination as! AddMusicViewController
            nextView.musicName = musicName
            nextView.artistName = artistName
            nextView.musicImage = try! Data(contentsOf: URL(string: musicImage)!)
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //キーボード以外がタップされた時にキーボードを閉じる
        self.searchBar.resignFirstResponder()
        
            
    }
    
    func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "CollectionViewCell2", bundle: nil), forCellWithReuseIdentifier: "customCollectionCell2")
        
        collectionView.keyboardDismissMode = .onDrag
    }
    
    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }
    
    func getMusicArticles(text: String) {
        //日本語をパソコン言語になおす
        let parameters = ["term": text, "country": "jp", "limit": "14"]
        //termが検索キーワード　countryが国　limitが数の上限
        //parameterを使ってsearch以降の文を書いている
        AF.request("https://itunes.apple.com/search", parameters: parameters).responseJSON { response in
            //if文みたいなやつ,この場合response.resultがsuccessの時とfailureの時で場合分けをしている
            switch response.result {
            case .success:
                //doはエラーが出なかった場合 catchはエラーが出たとき
                do {
                    let iTunesData: ITunesData = try self.decoder.decode(ITunesData.self, from: response.data!)
                    
                    self.musicInfoModel = iTunesData.results
                    
                    //dataが送られるまでにラグがあるからtextFieldChanged内ではなくこっちに書く
                    self.collectionView.reloadData()
                        
                } catch {
                    print("デコードに失敗しました")
                }
            case .failure(let error):
                print("error", error)
            }
        }
    }
    
    
    
//    @IBAction func textRecognition(_ sender: UIButton) {
//        let documentCameraViewController = VNDocumentCameraViewController()
//        documentCameraViewController.delegate = self
//        present(documentCameraViewController, animated: true)
//    }
//
//
//
//    func setupVision() {
//        let textRecognitionRequest = VNRecognizeTextRequest { request, _ in
//            guard let observations = request.results as? [VNRecognizedTextObservation] else {
//                print("The observations are of an unexpected type.")
//                return
//            }
//            // 解析結果の文字列を連結する
//            let maximumCandidates = 1
//            for observation in observations {
//                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
//                self.resultingText += candidate.string + "\n"
//                let box = observation.boundingBox // 位置のボックス
//                let topCandidate = observation.topCandidates(1)
//                if let recognizedText = topCandidate.first?.string { // 検出したテキスト
//                    print(recognizedText)
//                }
//            }
//        }
//        // 文字認識のレベルを設定
//        textRecognitionRequest.recognitionLevel = .accurate
//        let request = VNRecognizeTextRequest()
//        request.recognitionLanguages = ["ja-JP", "en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant"] // 言語を指定
//        self.requests = [textRecognitionRequest]
//    }
//
//
//
//    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//            controller.dismiss(animated: true)
//
//            // Dispatch queue to perform Vision requests.
//            let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue",
//                                                                 qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
//            textRecognitionWorkQueue.async {
//                self.resultingText = ""
//                for pageIndex in 0 ..< scan.pageCount {
//                    let image = scan.imageOfPage(at: pageIndex)
//                    if let cgImage = image.cgImage {
//                        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//
//                        do {
//                            try requestHandler.perform(self.requests)
//                        } catch {
//                            print(error)
//                        }
//                    }
//                }
//                DispatchQueue.main.async(execute: {
//                    print(self.resultingText)
//                    // textViewに表示する
//                    self.textView.text = self.resultingText
//
//                })
//            }
//        }
    
    
    
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        musicName = musicInfoModel[indexPath.row].trackName
        artistName = musicInfoModel[indexPath.row].artistName
        musicImage = musicInfoModel[indexPath.row].artworkUrl100
        
        performSegue(withIdentifier: "toAddMusic", sender: nil)
    }
}

extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        musicInfoModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCollectionCell2", for: indexPath) as! CollectionViewCell2
        
        cell.musicLabel?.text = String(musicInfoModel[indexPath.row].trackName)
        cell.artistLabel?.text = String(musicInfoModel[indexPath.row].artistName)
        
        let url = NSURL(string: self.musicInfoModel[indexPath.row].artworkUrl100)
        let req = NSURLRequest(url:url! as URL)

        NSURLConnection.sendAsynchronousRequest(req as URLRequest, queue:OperationQueue.main){(res, data, err) in
            let image = UIImage(data:data!)
            // 画像に対する処理 (UcellのUIImageViewに表示する等)
            cell.image?.image = image
            
        }
        
        return cell
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 200)
    }
}

extension SearchViewController: UISearchBarDelegate {
    //searchBarに値が入力されるごとに呼び出される変数
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getMusicArticles(text: searchText)
    }
    //改行したら自動的にキーボードを非表示にする
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
