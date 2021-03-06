// DGArtistViewController.swift
//
// Copyright (c) 2016 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import DiscogsAPI

class DGArtistViewController: DGViewController {
    
    fileprivate var response : DGArtistReleaseResponse! {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get artist details
        DiscogsAPI.client().database.getArtist(self.objectID, success: { (artist) in
            
            self.titleLabel.text    = artist.name
            self.styleLabel.text    = artist.profile
            
            if let members = artist.members {
                self.detailLabel.text   = self.membersAsString(members)
            }
            
            // Get a Discogs image
            if let image = artist.images?.first {
                DiscogsAPI.client().resource.getImage(image.resourceURL!, success: { (image) in
                    self.coverView?.image = image
                    }, failure:nil)
            }
            
            }) { (error) in
                print(error)
        }

        // Get artist release
        let request = DGArtistReleaseRequest()
        request.artistID = self.objectID
        request.pagination.perPage = 25
        
        DiscogsAPI.client().database .getArtistReleases(request, success: { (response) in
            self.response = response
            }) { (error) in
                print(error)
        }
    }
    
    func membersAsString(_ members: [DGMember]!) -> String {
        var names = [String]()
        for member in members {
            names.append(member.name!)
        }
        return names.joined(separator: ", ")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let result = self.response.releases[(indexPath as NSIndexPath).row]
            
            if let destination = segue.destination as? DGViewController {
                destination.objectID = result.id
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.response?.releases.count as Int? {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Releases"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let release = self.response.releases[(indexPath as NSIndexPath).row]
        let cell = dequeueReusableCellWithResult(release)
        
        cell.textLabel?.text       = release.title
        cell.detailTextLabel?.text = release.year?.stringValue
        cell.imageView?.image      = UIImage(named: "default-release")
        
        // Get a Discogs image
        DiscogsAPI.client().resource.getImage(release.thumb!, success: { (image) in
            cell.imageView?.image = image
            }, failure:nil)
        
        // Load the next response page
        if release === self.response.releases.last {
            self.response.loadNextPage(success: {
                self.tableView.reloadData()
                }, failure: { (error) in
                    print(error)
            })
        }
        
        return cell
    }
    
    func dequeueReusableCellWithResult(_ release : DGArtistRelease) -> UITableViewCell {
        
        if  release.type == "master" {
            return self.tableView.dequeueReusableCell(withIdentifier: "MasterCell")!
        }
        return self.tableView.dequeueReusableCell(withIdentifier: "ReleaseCell")!
    }
}
