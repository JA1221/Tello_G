import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    
    var timer: Timer?
    var timerFlag = false
    var t = 0.0
    var audioPlayer: AVAudioPlayer!
    var csv = [[String]]()
    var handle = 1
    var tello_Num = 0
    
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
        let csvUrl = Bundle.main.url(forResource: "TelloEDU_Charlie_Puth_Marvin_Gaye", withExtension: "csv")
        let line = try! String(contentsOf: csvUrl!).components(separatedBy: "\r\n")
        for i in line{
            csv.append(i.components(separatedBy: ","))
        }

        print(csv)
        //timer
        
    }
    //======================= timer ==========================
    //timer開始
    func timerStart(){
        if timerFlag==true {return}//運行中 return
        
        timerFlag = true
        timeHandle()
        //創建timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {(_) in
            self.t += 0.5
            self.timeHandle()
            self.timeLabel.text = "time : " + String(self.t) + "s"
        })
    }
    //結束timer
    func timerStop(){
        if timer != nil{//當timer存在時 廢止
            timer?.invalidate()
            timer = nil
            //初始化
            t = 0.0
            handle = 1
            timerFlag = false
        }
    }
    //timer處理
    func timeHandle(){
        if csv[handle][0] == String(t)+" "{//秒數到 執行
            print(csv[handle])
            handle += 1
            
            if csv[handle][0] == "end"{//遇到end 結束timer
                timerStop()
            }
        }
    }
    //=======================================
    @IBAction func timerStart(_ sender: Any) {
        timerStart()
    }
    
    //=================================================
    override func viewDidDisappear(_ animated: Bool) {
        timerStop()
    }
}

