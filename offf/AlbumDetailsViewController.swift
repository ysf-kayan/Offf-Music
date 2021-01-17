//
//  AlbumDetailsViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 4.10.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumDetailsTableAlbumCell: UITableViewCell {
    @IBOutlet weak var songTitleCell: UILabel!
    @IBOutlet weak var equalizerPlaceholder: UIView!
    var persistentId: MPMediaEntityPersistentID!;
}

class AlbumDetailsViewController: UITableViewController {
    
    var artistName = "";
    var albumName = "";
    
    var songs: [MPMediaItem] = [];

    var playerScreenCommand = PlayerCommand.SHOW_PLAYER;
    
    let eq = Equalizer();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.title = albumName;
        print("albumName: " + albumName);
        
        songs = SongList.getStructuredSongList()[artistName]![albumName]!;
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count;
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! AlbumDetailsTableAlbumCell;

        let song = songs[indexPath[1]];
        cell.songTitleCell.text = song.title;
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
        MusicPlayer.setQueue(newQueue: songs);
        MusicPlayer.play(startAt: indexPath[1]);
        playerScreenCommand = PlayerCommand.PLAY_NEW_LIST;
        
        self.performSegue(withIdentifier: "playFromAlbum", sender: self);
        tableView.deselectRow(at: indexPath, animated: true);
        
        let cell = tableView.cellForRow(at: indexPath) as! AlbumDetailsTableAlbumCell;
        if (cell.equalizerPlaceholder.subviews.count == 0) {
            Equalizer.embedIntoView(view: cell.equalizerPlaceholder, equalizer: eq);
        }
        tableView.visibleCells.map( {$0 as! AlbumDetailsTableAlbumCell} ).filter { (visibleCell) in
            return visibleCell != cell && visibleCell.equalizerPlaceholder.subviews.count > 0;
        }.forEach { (cellWithEq) in
            cellWithEq.equalizerPlaceholder.subviews.forEach { (subview) in
                subview.removeFromSuperview();
            }
        };
    }
    
    
    @IBAction func nowPlayingClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "playFromAlbum", sender: self);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playFromAlbum" {
            let dest = segue.destination as! PlayerScreenViewController;
            dest.command = playerScreenCommand;
            if (playerScreenCommand == PlayerCommand.PLAY_NEW_LIST) {
                dest.songList = songs;
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.visibleCells.map({$0 as! AlbumDetailsTableAlbumCell}).forEach { (cell) in
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
}
