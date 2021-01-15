import Foundation
import MediaPlayer
import UIKit

class SongList: NSObject {
    
    private static var allSongs: [MPMediaItem] = [];
    private static var structuredSongList = [String: [String: [MPMediaItem]]]();
    private static var artistSections: [String] = [];
    private static var artistsSectionStructure = [String: [String]]();
    private static var numberOfArtists = 0;
    private static var numberOfSongs = 0;
        
    override init() {
        let songs = MPMediaQuery.songs().items;
        if (songs != nil) {
            SongList.allSongs = songs!;
            
            var structuredSongList = [String: [String: [MPMediaItem]]]();
            
            for song in songs! {
                var artist: String? = nil;
                if (song.albumArtist != nil) {
                    artist = song.albumArtist!;
                } else if (song.artist != nil) {
                    artist = song.artist!;
                }
                
                if (artist == nil) {
                    continue;
                }
                                
                if (!structuredSongList.keys.contains(artist!)) {
                    structuredSongList[artist!] = [String: [MPMediaItem]]();
                }
                
                var album: String? = nil;
                if (song.albumTitle != nil) {
                    album = song.albumTitle!;
                }
                
                if (album == nil) {
                    continue;
                }
                
                var artistStructure = structuredSongList[artist!];
                
                if (!artistStructure!.keys.contains(album!)) {
                    artistStructure![album!] = [];
                }
                                
                
                var albumStructure = artistStructure![album!];
                
                albumStructure!.append(song);
                
                artistStructure![album!] = albumStructure;
                structuredSongList[artist!] = artistStructure;
            }
            
            SongList.structuredSongList = structuredSongList;
            
            var artistSectionsSet: Set<String> = [];
            
            let artistList = structuredSongList.keys.sorted {
                $0.compare($1, locale: Locale(identifier: "tr")) == .orderedAscending;
            };
            SongList.numberOfArtists = artistList.count;
            
            for artist in artistList {
                let section = String(artist.prefix(1));
                
                artistSectionsSet.insert(section);
                
                if (!SongList.artistsSectionStructure.keys.contains(section)) {
                    SongList.artistsSectionStructure[section] = [];
                }
                SongList.artistsSectionStructure[section]!.append(artist);
            }
            
            SongList.artistSections = Array(artistSectionsSet).sorted {
                $0.compare($1, locale: Locale(identifier: "tr")) == .orderedAscending;
            };
            
            /*SongList.artists = artistsSet.sorted {
                $0.compare($1, locale: Locale(identifier: "tr")) == .orderedAscending;
            }
            SongList.artistSections = artistSectionsSet.sorted {
                $0.compare($1, locale: Locale(identifier: "tr")) == .orderedAscending;
            }*/
            
            print("SongList: Şarkı listesi alındı.");
        } else {
            print("SongList: Şarkı listesi alınamadı!");
        }
        
    }
    
    static func getArtistSections() -> [String] {
        return SongList.artistSections;
    }
    
    static func getArtistsSectionStructure() -> [String: [String]] {
        return SongList.artistsSectionStructure;
    }
    
    static func getAllSongsList() -> [MPMediaItem] {
        return SongList.allSongs;
    }
    
    static func getStructuredSongList() -> [String: [String: [MPMediaItem]]] {
        return SongList.structuredSongList;
    }
    
    static func getNumberOfArtists() -> Int {
        return SongList.numberOfArtists;
    }
    
    static func getNumberOfSongs() -> Int {
        return SongList.allSongs.count;
    }
}
