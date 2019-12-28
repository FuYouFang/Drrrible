//
//  Networking.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 08/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import Moya
import MoyaSugar
import RxSwift

#warning("根据不同的 baseURL 将 API 进行分割")
typealias DrrribleNetworking = Networking<DribbbleAPI>

final class Networking<Target: SugarTargetType>: MoyaSugarProvider<Target> {
    init(plugins: [PluginType] = []) {
        let session = MoyaProvider<Target>.defaultAlamofireSession()
        #warning("设置请求超时时间")
        session.sessionConfiguration.timeoutIntervalForRequest = 10
        
        super.init(session: session, plugins: plugins)
    }
    
    func request(
        _ target: Target,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> Single<Response> {
        let requestString = "\(target.method.rawValue) \(target.path)"
        return self.rx.request(target)
            .filterSuccessfulStatusCodes()
            .do(
                onSuccess: { value in
                    let message = "SUCCESS: \(requestString) (\(value.statusCode))"
                    log.debug(message, file: file, function: function, line: line)
                },
                onError: { error in
                    // 判断 error 的具体类型
                    let message: String
                    if let response = (error as? MoyaError)?.response {
                        if let jsonObject = try? response.mapJSON(failsOnEmptyData: false) {
                            message = "FAILURE: \(requestString) (\(response.statusCode))\n\(jsonObject)"
                        } else if let rawString = try? response.mapString() {
                            message = "FAILURE: \(requestString) (\(response.statusCode))\n\(rawString)"
                        } else {
                            message = "FAILURE: \(requestString) (\(response.statusCode))"
                        }
                    } else {
                        message = "FAILURE: \(requestString)\n\(error)"
                    }
                    log.warning(message, file: file, function: function, line: line)
                },
                onSubscribed: {
                    let message = "REQUEST: \(requestString)"
                    log.debug(message, file: file, function: function, line: line)
            }
        )
    }
}
