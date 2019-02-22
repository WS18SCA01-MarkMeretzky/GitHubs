//
//  TableViewController.swift
//  GitHubs
//
//  Created by Mark Meretzky on 2/18/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;
import SafariServices;

class TableViewController: UITableViewController {
    
    @IBInspectable var section: String = ""; //"WS18SCA01" or "SF18AS01"
    var projects: [Project] = [Project]();   //the model (as in Model-View-Controller)

    override func viewDidLoad() {
        super.viewDidLoad();
        updateModelAndUI();

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false;

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // navigationItem.rightBarButtonItem = editButtonItem;
    }
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        updateModelAndUI();
    }
    
    //Called by viewDidLoad and refreshButtonPressed.
    
    func updateModelAndUI() {
        let urlString: String = "https://api.github.com/search/repositories"
            + "?q=\(section)-"     //Search for repositories that have section- in their name.
            + "+in:name"
            + "+sort:updated-desc" //The most recently updated repositories first. "desc" means descending.
            + "&per_page=100";     //Get at most 100 repositories.
        
        guard let url: URL = URL(string: urlString) else {
            fatalError("could not create URL for \(urlString)");
        }
        
        let downloadTask: URLSessionDownloadTask = URLSession.shared.downloadTask(with: url, completionHandler: completionHandler);
        downloadTask.resume();
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "\(section)reuseIdentifier", for: indexPath);

        // Configure the cell...
        //A cell of style UITableViewCell.CellStyle.subtitle
        //contains a big textLabel and a smaller detailTextLabel below it, both left justified.
        let project: Project = projects[indexPath.row];
        cell.textLabel?.text = project.name;
        cell.detailTextLabel?.text = project.updated;
        return cell;
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true;
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true;
    }
    */
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProject: Project = projects[indexPath.row];
        let s: String = "https://github.com/\(section)-\(selectedProject.name)/";

        guard let url: URL = URL(string: s) else {
            fatalError("could not create URL for \(s)");
        }
        
        let safariViewController: SFSafariViewController = SFSafariViewController(url: url);
        present(safariViewController, animated: true);
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//Called by updateModelAndUI when the download is complete.

func completionHandler(filename: URL?, response: URLResponse?, error: Error?) {
    print("completionHandler has been called");
    
    if (error != nil) {
        fatalError("could not download data from GitHub server: \(error!)");
    }
    
    guard let filename: URL = filename else {
        fatalError("The filename was nil.");
    }
    
    //Arrive here when the data from the GitHub has been
    //downloaded into a file in the device.
    
    //Copy the data from the file into a Data object.
    
    let data: Data;
    do {
        data = try Data(contentsOf: filename);
    } catch {
        fatalError("Could not create Data object: \(error)");
    }
    //print(String(data: data, encoding: .utf8)!)
    
    let dictionary: [String: Any];
    do {
        dictionary = try JSONSerialization.jsonObject(with: data) as! [String: Any];
    } catch {
        fatalError("could not create dictionary: \(error)");
    }
    
    guard let arrayOfDictionaries: [[String: Any]] = dictionary["items"] as? [[String: Any]] else {
        fatalError("JSON did not have array of items.");
    }
    
    let projects: [Project] = arrayOfDictionaries.map {
        guard var full_name: String = $0["full_name"] as? String else {
            fatalError("JSON item did not have full_name.");
        }
        
        if full_name.hasPrefix("WS18SCA01-") {
            full_name = String(full_name.dropFirst(10));
        } else if full_name.hasPrefix("SF18AS01-") {
            full_name = String(full_name.dropFirst(9));
        }
        
        guard let updated_at: String = $0["updated_at"] as? String else {
            fatalError("JSON item \(full_name) did not have updated_at.");
        }
    
        let dateFormatter: DateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX");
        guard let date: Date = dateFormatter.date(from: updated_at) else {
            fatalError("could not read date \(updated_at)");
        }
        
        dateFormatter.dateStyle = .full;   //show day of week
        dateFormatter.timeStyle = .long;
        let updated: String = dateFormatter.string(from: date)
        return Project(name: full_name, updated: updated);
    }
    
    DispatchQueue.main.async {
        //The following statements are executed by the main thread.
        guard let tabBarController: UITabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else {
            fatalError("could not find UITabBarController");
        }
        
        guard let navigationController: UINavigationController = tabBarController.selectedViewController as? UINavigationController else {
            fatalError("could not find UINavigationController");
        }
        
        guard let tableViewController: TableViewController = navigationController.topViewController as? TableViewController else {
            fatalError("could not find TableViewController");
        }
        
        tableViewController.projects = projects;
        tableViewController.tableView.reloadData();
    }
}
