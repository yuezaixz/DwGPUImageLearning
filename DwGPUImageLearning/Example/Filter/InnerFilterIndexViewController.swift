//
//  FilterIndexViewController.swift
//  DwGPUImageLearning
//
//  Created by 吴迪玮 on 2020/6/13.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit

class InnerFilterIndexViewController: UITableViewController {

    var filterDisplayViewController: InnerFilterDisplayViewController? = nil
    var objects = NSMutableArray()

    // #pragma mark - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let filterInList = filterOperations.filter { $0.filterOperationType == FilterOperationType.singleInput }[(indexPath as NSIndexPath).row]
                (segue.destination as! InnerFilterDisplayViewController).filterOperation = filterInList
            }
        }

    }

    // #pragma mark - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterOperations.filter { $0.filterOperationType == FilterOperationType.singleInput }.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let filterInList:FilterOperationInterface = filterOperations.filter { $0.filterOperationType == FilterOperationType.singleInput }[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = filterInList.listName
        return cell
    }
}

