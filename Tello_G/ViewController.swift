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
    var tello = [UDPClient]()
    let port = 8889
    var data = [String]()
    
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
        
        //創建tello 的 socket陣列
        create_Tello_UDP()
        recvData()
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
            send(csv[handle])
            handle += 1
            
            if csv[handle][0] == "end"{//遇到end 結束timer
                timerStop()
            }
        }
    }
    //=============== socket ===============
    func calc_Tello_Num(){
        tello_Num = csv[0].count - 1
        print(tello_Num)
    }
    func create_Tello_UDP(){
        calc_Tello_Num()
        
        for i in 1...tello_Num{
            tello.append(UDPClient(address: csv[0][i], port: Int32(port), myAddresss: "", myPort: Int32(port)))
        }
    }
    
    func close_Tello_UDP(){
        calc_Tello_Num()
        for i in 1...tello_Num{
            tello[i].close()
        }
    }
    //============== sned & recv ==============
    func send(_ s: [String]){
        for i in 1...tello_Num{
            _ = tello[i - 1].send(string: s[i])
        }
    }
    
    func recvData(){
        for i in 1...tello_Num{
            data.append("")
            
            let queue = DispatchQueue(label: "com.nkust.tello" + String(i))//宣告 label需要唯一性
            queue.async {
                while true{
                    let s = self.tello[i - 1].recv(20)//最多接收20
                    self.data[i-1] = self.get_String_Data(s.0!)
                    print("Tello" + String(i) + "recv:" + self.data[i-1])
                }
            }
        }
    }
    func get_String_Data(_ data: [Byte]) -> (String){
        let string1 = String(data: Data(data), encoding: .utf8) ?? ""
        return string1
    }
    //================== BT =====================
    @IBAction func timerStart(_ sender: Any) {
        timerStart()
    }
    //=================================================
    override func viewDidDisappear(_ animated: Bool) {
        timerStop()
        close_Tello_UDP()
    }
}

