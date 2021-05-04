/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller from which to invoke the document scanner.
*/

import UIKit
import VisionKit
import Vision

//    Bool for the "should the pages be numbered?" setting on main screen
// Used inside numberedPagesSwitch
var numberedPagesSwitchBool : Bool = false

class DocumentScanningViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static let contentsIdentifier = "contentsVC"
    
    
    @IBAction func asd(_ sender: Any) {
                title = "transcript core"
                view.addSubview(tableView)
                tableView.delegate = self
                tableView.dataSource = self
                tableView.frame = view.bounds
                getAllItems()
    }
    
//    ==============================================================
//                              CoreData
//    ==============================================================
//    CoreData - display all items
//    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    } ()
    
    private var models = [TranscriptEntity]()

    func getAllItems() {
        do {
            models = try context.fetch(TranscriptEntity.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
//           put some error handling here
        }
    }


    func createItem(transcriptBody: String) {
        let newItem = TranscriptEntity(context: context)
        newItem.transcriptBody = transcriptBody
        newItem.createdAt = Date()
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            // put some error handling here
        }
        
    }
    
    func deleteItem(item: TranscriptEntity) {
        context.delete(item)
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            // put some error handling here
        }
    }

    func updateItem(item: TranscriptEntity, newTranscriptBody: String) {
        item.transcriptBody = newTranscriptBody
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            // put some error handling here
        }
    }
    
    
//    ==============================================================
//                              End CoreData
//    ==============================================================
    
    
    
//    Switch for the "should the pages be numbered?" option
//    In "off" state by default (pages are not numbered)
    @IBAction func numberedPagesSwitch(_ sender: UISwitch) {
        if sender.isOn {
            view.backgroundColor = .red
            numberedPagesSwitchBool = true
        }
        else {
            view.backgroundColor = .blue
            numberedPagesSwitchBool = false
        }
    }
    
    //    enum ScanMode: Int {
//        case other
//    }
    
    var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()

    override func viewDidLoad() {
        super.viewDidLoad()
        getAllItems()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        
        //    ==============================================================
        //                              Test CoreData some other view that should probably be deleted cause it lauches into it disregarding any other views
        //    ==============================================================
//        title = "transcript core data"
//        view.addSubview(tableView)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.frame = view.bounds
        
        
        
        
        //    ==============================================================
        //                              Test End CoreData
        //    ==============================================================
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            guard let resultsViewController = self.resultsViewController else {
                print("resultsViewController is not set")
                return
            }
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        resultsViewController.addRecognizedText(recognizedText: requestResults)
                    }
                }
            }
        })
        // This doesn't require OCR on a live camera feed, select accurate for more accurate results.
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "new item", message: "enter", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "submit", style: .cancel, handler: {[weak self]_ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                return
            }
            self?.createItem(transcriptBody: text)
        }))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(model.transcriptBody) - \(model.createdAt)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = models[indexPath.row]
        let sheet = UIAlertController(title: "edit", message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        sheet.addAction(UIAlertAction(title: "edit", style: .default, handler: {_ in
            let alert = UIAlertController(title: "edit item", message: "edit item", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = item.transcriptBody
            alert.addAction(UIAlertAction(title: "save", style: .cancel, handler: {[weak self]_ in
                guard let field = alert.textFields?.first, let newTranscriptBody = field.text, !newTranscriptBody.isEmpty else {
                    return
                }
                self?.updateItem(item: item, newTranscriptBody: newTranscriptBody)
            }))
            self.present(alert, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "delete", style: .destructive, handler: {[weak self]_ in
            self?.deleteItem(item: item)
        }))
        
        present(sheet, animated: true)
    }

    @IBAction func scan(_ sender: UIControl) {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    
    func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }
}

extension DocumentScanningViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var vcID: String?
        vcID = DocumentScanningViewController.contentsIdentifier
    
        
        if let vcID = vcID {
            resultsViewController = storyboard?.instantiateViewController(withIdentifier: vcID) as? (UIViewController & RecognizedTextDataSource)
        }
        
        self.activityIndicator.startAnimating()
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
                DispatchQueue.main.async {
                    if let resultsVC = self.resultsViewController {
                        self.navigationController?.pushViewController(resultsVC, animated: true)
                    }
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
}
