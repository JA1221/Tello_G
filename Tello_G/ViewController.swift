import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var csvNameLabel: UILabel!
    @IBOutlet weak var musicNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var flyBt: UISwitch!
    
//timer計時器
    var timer: Timer?
    var timerFlag = false
    var t = 0.0
//音樂
    var audioPlayer: AVAudioPlayer!
//csv處理
    var csv = [[String]]()
    var handle = 1 //處理第幾行
//tello Socket
    var tello_Num = 0
    var tello = [UDPClient]() //UDP 通訊陣列
    let port = 8889 //Tello 接收端口
    let sendPort_1st = 60000 // 發送端口起始編號 ex. 1:6000, 2:6001, 3: 6002
    var data = [String]()
//==================== 畫面載入 ==========================
    override func viewDidLoad() {
        super.viewDidLoad()
        
    //圓角
        timeLabel.layer.cornerRadius = 10
        instruction.layer.cornerRadius = 10
        
    //prepare music
        let musicUrl = Bundle.main.url(forResource: "music", withExtension: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: musicUrl!)
            audioPlayer.prepareToPlay()
        } catch {
            print("Error:", error.localizedDescription)
        }
        
    //read csv ＆ 存成二維陣列
        let csvUrl = Bundle.main.url(forResource: "TelloEDU_Charlie_Puth_Marvin_Gaye", withExtension: "csv")
        let content = try! String(contentsOf: csvUrl!)
        csv = csv_To_Array(content)
        print(csv)
        
    //將預設檔案寫入資料夾
        saveFile(source: csvUrl!, destination: nil, fileName: "default.csv")
        saveFile(source: musicUrl!, destination: nil, fileName: "default.mp3")
        
    //創建tello 的 socket陣列
        create_Tello_UDP()
        recvData()
    }
//==================== 檔案處理 ==========================
    func saveFile(source: URL, destination: URL?, fileName: String){
        var dest = destination
        if dest==nil{
            dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        dest = dest!.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: dest!.path){
            print(fileName + " already exists!")
        }else{
            do{
                try FileManager.default.copyItem(at: source, to: dest!)
            }
            catch{
                print("Error: \(error)")
            }
        }
    }
//======================= timer ==========================
//timer開始
    func timerStart(){
        if timerFlag==true {return}//運行中 return
        timerFlag = true//旗標設定

        //接收資料區清空 ＆ 處理
        data_clear()
        timeHandle()
        
        //創建timer 每0.5秒執行一次
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {(_) in
            self.t += 0.5
            self.timeHandle()
            self.timeLabel.text = "Time : " + String(self.t) + "s"
        })
    }
    
//結束timer
    func timerStop(){
    //switch 關
        flyBt.setOn(false, animated: true)
    //停止音樂並關歸零
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        
        if timer != nil{//當timer存在時 廢止
            timer?.invalidate()
            timer = nil
        //初始化
            t = 0.0
            handle = 1
            timerFlag = false
            self.timeLabel.text = "Time : " + String(self.t) + "s"
        }
    }
//timer處理
    func timeHandle(){
        if Double(csv[handle][0]) == t{//秒數到指令設定的秒數 執行
            print(csv[handle])
            
            for i in 1...tello_Num{
                if csv[handle][i] != ""{//i號機有指令
                    //前一個沒做完 (第一個指令除外) 啟動安全機制
                    if data[i - 1] != "ok" && t != 0.0{
                        //stop 編號 1 ~ n
                        print(String(i) + "號無人機脫隊, 全體迫降")
                        show(String(i) + "號無人機脫隊, 全體迫降")
                        send("stop")
                        send("land")
                        timerStop()
                        return
                    //安全 可執行指令前清空接收區
                    }else{
                        data[i - 1] = ""
                    }
                }
            }
            send(csv[handle])//傳送指令
            handle += 1//下一條指令
            
            if csv[handle][0] == "end" || csv[handle][0] == ""{//時間軸遇到 "end" or 沒標示時間 -> 結束timer
                timerStop()
                show("結束")
            }
        }
    }
//=============== socket ===============
    func calc_Tello_Num(){//計算tello數量
        tello_Num = csv[0].count - 1
    }
    
    func create_Tello_UDP(){//創建udp socket
        close_Tello_UDP()
        calc_Tello_Num()
        
        for i in 1...tello_Num{
            tello.append(UDPClient(address: csv[0][i], port: Int32(port), myAddresss: "", myPort: Int32(sendPort_1st + i)))
        }
    }
    
    func close_Tello_UDP(){//關閉 udp socket
        //關閉socket
        for i in 0..<tello.count{
            tello[i].close()
        }
        //將Tello 陣列初始化
        tello = [UDPClient]()
    }
//============== sned & recv ==============
    func send(_ s: [String]){//傳送String陣列給 所有無人機
        for i in 1...tello_Num{
            _ = tello[i - 1].send(string: s[i])
        }
    }
    func send(_ s: String){//傳送單一指令給 所有無人機
        for i in 1...tello_Num{
            _ = tello[i - 1].send(string: s)
        }
    }
    func send(_ n:Int, _ s: String){//傳送單一指令給 指定無人機
            _ = tello[n].send(string: s)
    }
    func recvData(){//接收資料 多執行緒
        data = [String]() //接收區大小重設
        
        for i in 0..<tello.count{
            data.append("")//增加陣列
            let queue = DispatchQueue(label: "com.nkust.tello" + String(i + 1))//宣告 label需要唯一性 無人機個別擁有 獨立執行緒
            
            queue.async {
                while true{
                    print(String(i + 1) + " is listening.")
                    let s = self.tello[i].recv(20)//接收 最多20字元data
                    if s.0==nil{break}//被強制結束 跳出
                    
                    self.data[i] = self.get_String_Data(s.0!)//儲存
                    print("Tello" + String(i + 1) + ", recv:" + self.data[i])//印出接收到的資料(ex. Tello1, recv:OK)
                }
                print("Tello" + String(i + 1) + " is closed.")
            }
        }
    }
    func get_String_Data(_ data: [Byte]) -> (String){//轉換陣列->String
        let string1 = String(data: Data(data), encoding: .utf8) ?? ""
        return string1
    }
    
    func data_clear(){//清空接收的data
        for i in 0..<data.count{
            data[i] = ""
        }
    }
//================== BT =====================

    @IBAction func command(_ sender: Any) {
        send("command")
    }
    @IBAction func takeoff(_ sender: Any) {
        send("takeoff")
    }
    @IBAction func land(_ sender: Any) {
        send("land")
    }
    @IBAction func emergency(_ sender: Any) {
        send("emergency")
    }
//=================== Switch ==================
    @IBAction func begin(_ sender: UISwitch) {
        if sender.isOn == true{
            audioPlayer.play()//播放音樂
            timerStart()//timer啟動
            show("開始")
        }else{
            //tello降落
            timerStop()
            send("stop")
            send("land")
            show("降落中...三秒後關閉引擎")
            sleep(3)
            send("emergency")//安全起見 三秒後關閉引擎
            show("手動結束！")
            alert("已手動結束！")
        }
    }
    
    func show(_ s:String){
        DispatchQueue.main.async {
            self.instruction.text = s
        }
    }
//=================== read CSV ====================
    @IBAction func readCSV(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.plain-text"], in: .open)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func csv_To_Array(_ s: String)->([[String]]){
        var array = [[String]]()
        
        let line = s.components(separatedBy: "\r\n")
        for i in line{
            array.append(i.components(separatedBy: ","))
        }
        
        return array
    }
//================== read mp3 =====================
    @IBAction func readMusic(_ sender: Any) {
        let musicPicker = UIDocumentPickerViewController(documentTypes: ["public.mp3"], in: .open)
        musicPicker.delegate = self
        musicPicker.allowsMultipleSelection = false
        present(musicPicker, animated: true, completion: nil)
    }
//================== new ==========================
    func isIP(_ IP:String?) -> Bool{
        guard let IP = IP else { return false}//nil
        
        let s = IP.components(separatedBy: ".")
        if s.count != 4{ return false}//not *.*.*.*
        
        for i in s{
            guard let n = Int(i) else{ return false}//not Int
            
            if n < 0 || n > 255{ return false}//not 0~255
        }
        
        return true
    }
    
    func check_CSV_IPformat(_ csv:[[String]]) ->Bool{
        var check = true
        
        if csv[0].count < 2 {//沒填入IP
            return false
        }
        
        for i in 1..<csv[0].count{
            check = check && isIP(csv[0][i])
        }
        
        return check
    }
    
    func alert(_ string:String?){
        let alert = UIAlertController(title: "訊息窗", message: string, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
//=================================================
    override func viewDidDisappear(_ animated: Bool) {
        timerStop()
    }
}

extension ViewController: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else{ return}
        
        let fileName = selectedFileURL.lastPathComponent.components(separatedBy: ".")
        let fileType = fileName[fileName.count - 1]//取副檔名
        
        //*** csv檔處理 ***
        if fileType == "csv"{
            let s = try! String(contentsOf: selectedFileURL)
            
            csv = csv_To_Array(s)
            print(csv)
            create_Tello_UDP()//重新宣告UDP
            recvData()//開啟資料接收
            csvNameLabel.text = selectedFileURL.lastPathComponent//顯示csv檔名
        //*** mp3檔處理 ***
        }else if fileType == "mp3"{
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: selectedFileURL)
                audioPlayer.prepareToPlay()
                musicNameLabel.text = selectedFileURL.lastPathComponent//顯示mp3檔名
            } catch {
                print("Error:", error.localizedDescription)
            }
        }else{
            alert("僅能讀取 .csv 或 .mp3")
        }
    }
}
