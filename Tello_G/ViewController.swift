import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    var timer: Timer?
    var t = 0.0
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
        
        //timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {(_) in
            self.t += 0.5
            self.timeLabel.text = "time : " + String(self.t) + "s"
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if timer != nil{
            timer?.invalidate()
        }
    }
}

