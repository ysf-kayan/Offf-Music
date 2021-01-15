//
//  SecondViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 17.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

class AllSongsTableViewCell : UITableViewCell {
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var equalizerPlaceholder: UIView!
    var persistentId: MPMediaEntityPersistentID!;
}

class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var allSongsTable: UITableView!
    @IBAction func nowPlayingClicked(_ sender: UIBarButtonItem) {
        playerScreenCommand = PlayerCommand.SHOW_PLAYER;
        self.performSegue(withIdentifier: "playFromAllSongsList", sender: self);
    }
    
    var playerScreenCommand: PlayerCommand = PlayerCommand.SHOW_PLAYER;
    var songListToPlay: [MPMediaItem] = [];
    
    var eq = Equalizer();
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionSongDict[sections[section]]!.count;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section];
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count;
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath[0]];
        let song = sectionSongDict[section]![indexPath[1]];
                
        let index = findObjectIndexInArray(array: allSongsQueue, object: song);
        MusicPlayer.setQueue(newQueue: allSongsQueue);
        MusicPlayer.play(startAt: index);
        
        playerScreenCommand = PlayerCommand.PLAY_NEW_LIST;
        self.performSegue(withIdentifier: "playFromAllSongsList", sender: self);
        tableView.deselectRow(at: indexPath, animated: true);
                
        let cell = tableView.cellForRow(at: indexPath) as! AllSongsTableViewCell;
        if (cell.equalizerPlaceholder.subviews.count == 0) {
            Equalizer.embedIntoView(view: cell.equalizerPlaceholder, equalizer: eq);
        }
        tableView.visibleCells.map( {$0 as! AllSongsTableViewCell} ).filter { (visibleCell: AllSongsTableViewCell) in
            return visibleCell != cell && visibleCell.equalizerPlaceholder.subviews.count > 0;
        }.forEach { (cellWithEq) in
            cellWithEq.equalizerPlaceholder.subviews.forEach { (subview) in
                subview.removeFromSuperview();
            }
        };
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath) as! AllSongsTableViewCell;
                
        let section = sections[indexPath[0]];
        let song = sectionSongDict[section]![indexPath[1]];
        cell.songTitleLabel.text = song.title;
        cell.artistAlbumLabel.text = song.artist! + " - " + song.albumTitle!;
        cell.persistentId = song.persistentID;
        
        if (song.persistentID == MusicPlayer.getCurrentItem()?.persistentID) {
            if (cell.equalizerPlaceholder.subviews.count == 0) {
                Equalizer.embedIntoView(view: cell.equalizerPlaceholder, equalizer: eq);
            }
        } else {
            if (cell.equalizerPlaceholder.subviews.count > 0) {
                cell.equalizerPlaceholder.subviews[0].removeFromSuperview();
            }
        }
        
        return cell;
    }

    var sections: [String] = [];
    var sectionSongDict = [String: [MPMediaItem]]();
    var allSongsQueue = [MPMediaItem]();
    var totalSongLength = 0;
    var finishedTableLayout = false;
    let shuffleButton = ShuffleTheListButton();
    
    func initApp() {
        
        let songItems = SongList.getAllSongsList();
        
        for songItem in songItems {
            let title = songItem.title;
            if (title != nil) {
                let firstChar: String = String(title!.prefix(1));
                
                if (AppGlobals.isAlpha(val: firstChar)) {
                    let firstCharUppercase = firstChar.localizedUppercase;
                    if (!sectionSongDict.keys.contains(firstCharUppercase)) {
                        sectionSongDict[firstCharUppercase] = [MPMediaItem]();
                        sections.append(firstCharUppercase);
                    }
                    sectionSongDict[firstCharUppercase]?.append(songItem);
                } else {
                    if (!sectionSongDict.keys.contains("#")) {
                        sectionSongDict["#"] = [MPMediaItem]();
                    }
                    sectionSongDict["#"]?.append(songItem);
                }
                
                totalSongLength += Int(songItem.playbackDuration);
            }
        }
        sections.sort();
        if (sectionSongDict.keys.contains("#")) {
            sections.append("#");
        }
        
        for section in sections {
            //print(section);
            let songsOfSection = sectionSongDict[section];
            
            for song in songsOfSection! {
                allSongsQueue.append(song);
                //print(song.title!);
            }
        }
        
        allSongsTable.reloadData();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        print("AllSongsViewController");
        initApp();
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playFromAllSongsList" {
            let dest = segue.destination as! NewPlayerScreenViewController;
            dest.command = playerScreenCommand;
            if (playerScreenCommand == PlayerCommand.PLAY_NEW_LIST) {
                dest.songList = songListToPlay;
            }
        }
    }
    
    func findObjectIndexInArray(array: [MPMediaItem], object: MPMediaItem) -> Int {
        var i = 0;
        while (i < array.count && array[i] != object) {
            i += 1;
        }
        if (i == array.count) {
            return -1;
        }
        return i;
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if (finishedTableLayout) {
            updateEqualizerIconWhenViewAppear();
        }
    }
    
    override func viewDidLayoutSubviews() {
        if (allSongsTable.visibleCells.count > 0) {
            addShuffleHeader();
            addFooter();
        }
        finishedTableLayout = true;
        updateEqualizerIconWhenViewAppear();
    }
    
    private func addFooter() {
        let timeText = AppGlobals.createTotalLengthText(totalSongLength: totalSongLength);
        
        let footerText = "\(SongList.getNumberOfSongs()) Songs • \(timeText)";
        allSongsTable.tableFooterView = AppGlobals.createTableFooter(table: allSongsTable, text: footerText);
    }
    
    private func updateEqualizerIconWhenViewAppear() {
        allSongsTable.visibleCells.map({$0 as! AllSongsTableViewCell}).forEach { (cell) in
            if (cell.persistentId == MusicPlayer.getCurrentItem()?.persistentID) {
                if (cell.equalizerPlaceholder.subviews.count == 0) {
                    Equalizer.embedIntoView(view: cell.equalizerPlaceholder, equalizer: eq);
                }
            } else {
                cell.equalizerPlaceholder.subviews.forEach { (v) in
                    v.removeFromSuperview();
                }
            }
        }
    }
    
    @objc func shuffleButtonClicked() {
        MusicPlayer.setQueue(newQueue: allSongsQueue);
        MusicPlayer.setShuffle(shuffle: .SHUFFLE);
        MusicPlayer.play(startAt: 0);
        
        playerScreenCommand = PlayerCommand.PLAY_NEW_LIST;
        self.performSegue(withIdentifier: "playFromAllSongsList", sender: self);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shuffleButton.onTouchUpButton();
        }
    }
    
    private func addShuffleHeader() {
        shuffleButton.button.addTarget(self, action: #selector(shuffleButtonClicked), for: .touchUpInside);
        
        allSongsTable.tableHeaderView = shuffleButton;
        allSongsTable.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: allSongsTable.frame.width, height: 50);
    }
}

