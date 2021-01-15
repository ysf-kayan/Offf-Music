//
//  FirstViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 17.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistsTableArtistCell: UITableViewCell {
    
    @IBOutlet weak var artistLabel: UILabel!
}

class ArtistsTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    var parent: ArtistsViewController;
    
    init(parentView: ArtistsViewController) {
        self.parent = parentView;
    }
    
    var sections = SongList.getArtistSections();
    var artistsSectionStructure = SongList.getArtistsSectionStructure();

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artistsSectionStructure[sections[section]]!.count;
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistCell", for: indexPath) as! ArtistsTableArtistCell;
        
        let section = sections[indexPath[0]];
        let artist = artistsSectionStructure[section]![indexPath[1]];
        cell.artistLabel.text = artist;
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath[0]];
        let selectedArtistName = artistsSectionStructure[section]![indexPath[1]];

        parent.selectedArtist = selectedArtistName;
        
        parent.performSegue(withIdentifier: "showAlbumsOfArtist", sender: self);
        
        tableView.deselectRow(at: indexPath, animated: true);
    }
}

class ArtistsViewController: UIViewController {
    
    @IBOutlet weak var artistsTable: UITableView!
    var selectedArtist = "";
    
    var artistsTableDataSource: ArtistsTableDataSource? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        print("ArtistsViewController");
        
        let hasPermission = hasPermissionToUseMediaLibrary();
        if (!hasPermission) {
            requestPermissionToUseMediaLibrary();
        } else {
            initView();
        }
    }
    
    private func initView() {
        artistsTableDataSource = ArtistsTableDataSource(parentView: self);
        artistsTable.dataSource = artistsTableDataSource!;
        artistsTable.delegate = artistsTableDataSource!;
        artistsTable.reloadData();
    }
    
    func hasPermissionToUseMediaLibrary() -> Bool {
        return MPMediaLibrary.authorizationStatus() == MPMediaLibraryAuthorizationStatus.authorized;
    }
    
    func requestPermissionToUseMediaLibrary() {
        MPMediaLibrary.requestAuthorization { (status) in
            if (self.hasPermissionToUseMediaLibrary()) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    _ = SongList();
                    self.initView();
                }
            }
        }
    }
    
    @IBAction func nowPlayingClicked(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "showPlayer", sender: self);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlbumsOfArtist" {
            let dest = segue.destination as! AlbumsOfArtistsViewController;
            dest.artistName = selectedArtist;
        }
    }
    
    override func viewDidLayoutSubviews() {
        if (artistsTable.visibleCells.count > 0) {
            addFooter();
        }
    }
    
    private func addFooter() {
        artistsTable.tableFooterView = AppGlobals.createTableFooter(table: artistsTable, text: "\(SongList.getNumberOfArtists()) Artists");
    }
}

