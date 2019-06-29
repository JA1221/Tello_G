import UIKit
import AVFoundation

class ViewController: UIViewController {

    var audioPlayer: AVAudioPlayer!
    var csv = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //play music
        let musicUrl = Bundle.main.url(forResource: "music", withExtension: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: musicUrl!)
            audioPlayer.prepareToPlay()
        } catch {
            print("Error:", error.localizedDescription)
        }
        audioPlayer.play()
        
        //read csv
        let csvUrl = Bundle.main.url(forResource: "TelloEDU_Charlie_Puth_Marvin_Gaye ", withExtension: "csv")
        let line = try! String(contentsOf: csvUrl!).components(separatedBy: "\r\n")
        for i in line{
            csv.append(i.components(separatedBy: ","))
        }

        print(csv)
    }
}

