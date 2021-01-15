//
//  SongsOfArtistViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 13.10.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

class SongsOfArtistTableViewCell : UITableViewCell {
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var equalizerPlaceholder: UIView!
    var persistentId: MPMediaEntityPersistentID!;
}

struct SongWrapper {
    var songMediaItem: MPMediaItem;
    var songListArrayIndex: Int;
}

class SongsOfArtistViewController: UITableViewController {

    var artistName = "";
    
    var sections: [String] = [];
    var songList: [MPMediaItem] = [];
    var songsSectionStructure = [String: [SongWrapper]]();
    
    var playerScreenCommand = PlayerCommand.SHOW_PLAYER;
    
    var selectedSong = "";
    
    let eq = Equalizer();
    
    var totalSongLength = 0;
    
    let shuffleButton = ShuffleTheListButton();
        
    override func viewDidLoad() {
        super.viewDidLoad();
        
        let albums = SongList.getStructuredSongList()[artistName];
        var sectionSet = Set<String>();
        
        albums!.forEach({(albumName, songsInAlbum) in
            songsInAlbum.forEach({(song) in
                songList.append(song);
                totalSongLength += Int(song.playbackDuration);
            });
        });
        
        songList = songList.sorted(by: {(a, b) in
            return a.title!.compare(b.title!, locale: Locale(identifier: "tr")) == .orderedAscending;
        });
        
        songList.enumerated().forEach({(index, song) in
            let songTitle = song.title!;
            let section = String(songTitle.prefix(1));
            sectionSet.insert(section);
            
            if (!songsSectionStructure.keys.contains(section)) {
                songsSectionStructure[section] = [SongWrapper]();
            }
            
            var sectionSongList = songsSectionStructure[section];
            let songWrapper = SongWrapper(songMediaItem: song, songListArrayIndex: index);
            sectionSongList!.append(songWrapper);
            songsSectionStructure[section] = sectionSongList;
        });
        
        sections = Array(sectionSet).sorted(by: {(a, b) in
            return a.compare(b, locale: Locale(identifier: "tr")) == .orderedAscending;
        });
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count;
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections;
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section];
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songsSectionStructure[sections[section]]!.count;
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongsOfArtistTableViewCell;
        
        let section = sections[indexPath[0]];
        let songWrapper = songsSectionStructure[section]![indexPath[1]];
        let song = songWrapper.songMediaItem;
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath[0]];
        let songWrapper = songsSectionStructure[section]![indexPath[1]];
        
        MusicPlayer.setQueue(newQueue: songList);
        MusicPlayer.play(startAt: songWrapper.songListArrayIndex);
        
        playerScreenCommand = PlayerCommand.PLAY_NEW_LIST;
        self.performSegue(withIdentifier: "playFromSongsOfArtistList", sender: self);
        tableView.deselectRow(at: indexPath, animated: true);
        
        let cell = tableView.cellForRow(at: indexPath) as! SongsOfArtistTableViewCell;
        if (cell.equalizerPlaceholder.subviews.count == 0) {
            Equalizer.embedIntoView(view: cell.equalizerPlaceholder, equalizer: eq);
        }
        tableView.visibleCells.map( {$0 as! SongsOfArtistTableViewCell} ).filter { (visibleCell) in
            return visibleCell != cell && visibleCell.equalizerPlaceholder.subviews.count > 0;
        }.forEach { (cellWithEq) in
            cellWithEq.equalizerPlaceholder.subviews.forEach { (subview) in
                subview.removeFromSuperview();
            }
        };
    }

    
    @IBAction func nowPlayingClicked(_ sender: Any) {
        playerScreenCommand = PlayerCommand.SHOW_PLAYER;
        self.performSegue(withIdentifier: "playFromSongsOfArtistList", sender: self);
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playFromSongsOfArtistList" {
            let dest = segue.destination as! NewPlayerScreenViewController;
            dest.command = playerScreenCommand;
            if (playerScreenCommand == PlayerCommand.PLAY_NEW_LIST) {
                dest.songList = songList;
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.visibleCells.map({$0 as! SongsOfArtistTableViewCell}).forEach { (cell) in
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
    
    var finishedFirstLayout = false;
    
    override func viewDidLayoutSubviews() {
        if (!finishedFirstLayout) {
            finishedFirstLayout = true;
            addShuffleHeader();
            addFooter();
        }
    }
    
    private func addFooter() {
        let timeText = AppGlobals.createTotalLengthText(totalSongLength: totalSongLength);
        
        let footerText = "\(songList.count) Songs • \(timeText)";
        tableView.tableFooterView = AppGlobals.createTableFooter(table: tableView, text: footerText);
    }
    
    private func addShuffleHeader() {
        shuffleButton.button.addTarget(self, action: #selector(shuffleButtonClicked), for: .touchUpInside);
        
        tableView.tableHeaderView = shuffleButton;
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50);
    }
    
    @objc func shuffleButtonClicked() {
        MusicPlayer.setQueue(newQueue: songList);
        MusicPlayer.setShuffle(shuffle: .SHUFFLE);
        MusicPlayer.play(startAt: 0);
        
        playerScreenCommand = PlayerCommand.PLAY_NEW_LIST;
        self.performSegue(withIdentifier: "playFromSongsOfArtistList", sender: self);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.shuffleButton.onTouchUpButton();
        }
    }

}
