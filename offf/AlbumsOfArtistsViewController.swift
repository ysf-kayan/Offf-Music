//
//  AlbumsOfArtistsViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 24.08.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class AlbumsOfArtistTableAlbumCell: UITableViewCell {
    @IBOutlet weak var albumLabel: UILabel!
    
}

class AlbumsOfArtistsViewController: UITableViewController {
    
    var artistName = "";
    
    var sections: [String] = [];
    var albumsSectionStructure = [String: [String]]();
    
    var selectedAlbum = "";
    
    var allSongsOfArtistButton: AllSongsOfArtistButton? = nil;
    
    
    @IBAction func nowPlayingClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "showPlayer", sender: self);
    }
    
    
    @objc func allSongsButtonClicked() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.allSongsOfArtistButton!.onTouchUpButton();
        }
        performSegue(withIdentifier: "showSongsOfArtist", sender: self);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
                
        allSongsOfArtistButton = AllSongsOfArtistButton();
        allSongsOfArtistButton!.button.addTarget(self, action: #selector(allSongsButtonClicked), for: .touchUpInside);
        
        tableView.tableHeaderView = allSongsOfArtistButton;
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50);
        
        
        self.title = artistName;
                
        let albumNames = SongList.getStructuredSongList()[artistName]?.keys;
        
        var sectionsSet = Set<String>();
        
        for albumName in albumNames! {
            sectionsSet.insert(String(albumName.prefix(1)));
        }
        
        sections = Array(sectionsSet).sorted {
            $0.compare($1, locale: Locale(identifier: "tr")) == .orderedAscending;
        };
        
        for albumName in albumNames! {
            let section = String(albumName.prefix(1));
                        
            if (!albumsSectionStructure.keys.contains(section)) {
                albumsSectionStructure[section] = [];
            }
            albumsSectionStructure[section]!.append(albumName);
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section];
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumsSectionStructure[sections[section]]!.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! AlbumsOfArtistTableAlbumCell;

        let section = sections[indexPath[0]];
        let album = albumsSectionStructure[section]![indexPath[1]];
        cell.albumLabel.text = album;
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath[0]];

        selectedAlbum = albumsSectionStructure[section]![indexPath[1]];
        
        performSegue(withIdentifier: "showAlbumDetails", sender: self);
                
        tableView.deselectRow(at: indexPath, animated: true);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlbumDetails" {
            let dest = segue.destination as! AlbumDetailsViewController;
            dest.artistName = artistName;
            dest.albumName = selectedAlbum;
        } else if segue.identifier == "showSongsOfArtist" {
            let dest = segue.destination as! SongsOfArtistViewController;
            dest.artistName = artistName;
        }
    }

}
