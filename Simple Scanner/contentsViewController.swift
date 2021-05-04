/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 View controller for unstructured text.
 */

import UIKit
import Vision
import AVFoundation

class contentsViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView?
    
    var pageIndex : Int = 1
    var transcript = ""
    let synthesizer = AVSpeechSynthesizer()
    
//    ==============================================================
//                              CoreData
//    ==============================================================
//    CoreData - display all items

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

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
    
    
    
    //The "Copy to clipboard" button action. Does just that
    @IBAction func copyToClipboard(_ sender: Any) {
        //        UIPasteboard.general.string = transcript
        UIPasteboard.general.string = textView?.text
        didTapDone()
    }
    //
    
    //    Create a button for sharing
    private let button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .link
        button.setTitle("sharebutton", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()
    
    //   Create button for voice synthesis
    @IBAction func voiceToggleButton(_ sender: UIButton) {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
            view.backgroundColor = .brown
        } else {
            vocals()
            view.backgroundColor = .yellow
        }
    }
    
    //    (_ sender: UIButton) is a requirement for iPad to correctly
    //    display shareButton contents. Just for iOS () would've sufficed
    @objc private func presentShareSheet(_ sender: UIButton) {
        
        let shareSheetVC = UIActivityViewController(
            activityItems: [
                transcript
            ], applicationActivities: nil
        )
        //        for the shareButton to work on iPads
        shareSheetVC.popoverPresentationController?.sourceView = sender
        shareSheetVC.popoverPresentationController?.sourceRect = sender.frame
        //        show the share sheet
        present(shareSheetVC, animated: true)
    }
    //
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAllItems()
        //        add a share button onto the content view
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        button.center = view.center
        //        (_:) for iPad small-sized share window to correctly pop up
        button.addTarget(self, action: #selector(presentShareSheet(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        //        A toolbar above the keyboard with a 'done' option
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didTapDone))
        toolBar.items = [flexibleSpace, doneButton]
        toolBar.sizeToFit()
        textView?.inputAccessoryView = toolBar
        //        textView?.text = transcript
        textView?.text = transcript
        
    }
    
    //done button keyboard action
    @objc private func didTapDone() {
        textView?.resignFirstResponder()
        //        transcript = textView?.text ?? "aa"
    }
    func vocals() {
        let textToSpeech = AVSpeechUtterance(string: transcript)
        textToSpeech.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(textToSpeech)
    }
}


// MARK: RecognizedTextDataSource
extension contentsViewController: RecognizedTextDataSource {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        vocals()
        // If user preference was to display numbered pages
        if numberedPagesSwitchBool == true {
            transcript += "Page \(pageIndex) \n"
            pageIndex += 1
            createTranscript()
        }
        // If user preference was to NOT display numbered pages
        else { createTranscript() }
        
        //    Reusable transcript creation code for addRecognizedText func
        func createTranscript() {
            // Create a full transcript to run analysis on.
            let maximumCandidates = 1
            for observation in recognizedText {
                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                transcript += candidate.string
                //            transcript += "\n"
                transcript += " "
            }
            transcript += "\n"
            createItem(transcriptBody: transcript)
            
            
        }
        
    }
    
    

}
