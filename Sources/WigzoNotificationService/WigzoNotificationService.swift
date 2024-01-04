import UserNotifications

class WigzoNotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
    
//        guard let bestAttemptContent = bestAttemptContent,  let attachmentURLAsString = bestAttemptContent.userInfo["podcast-image"] as? String, let attachmentURL = URL(string: attachmentURLAsString ) else {
//            return
//        }
//
        
        guard let bestAttemptContent = bestAttemptContent,let fcmDict = bestAttemptContent.userInfo["fcm_options"] as? [String:String] ,let attachmentURLAsString = fcmDict["image"],let attachmentURL = URL(string: attachmentURLAsString) else {
            return
        }
        
        downloadImageFrom(url: attachmentURL) { (attachement) in
            if let attachment = attachement {
                bestAttemptContent.attachments = [attachment]
                bestAttemptContent.title = "\(bestAttemptContent.title)"
                contentHandler(bestAttemptContent)
            }
        }

    }
    
    private func downloadImageFrom(url:URL, with completionHandler: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedurl, response, error) in
            guard let downloadedUrl = downloadedurl else {
                completionHandler(nil)
                return
            }
            
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            
            let uniqueURLending = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            urlPath = urlPath.appendingPathComponent(uniqueURLending)
            
            try? FileManager.default.moveItem(at: downloadedUrl, to: urlPath)
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "picture", url: urlPath, options: nil)
                completionHandler(attachment)
            }
            catch {
                completionHandler(nil)
            }
        }
        task.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

