//
//  AuthPlugin.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 09/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import Moya

#warning("""
公共的参数通过 Plugin 的方式进行添加
例如：在请求头添加鉴权 token
""")
struct AuthPlugin: PluginType {
    fileprivate let authService: AuthServiceType
    
    init(authService: AuthServiceType) {
        self.authService = authService
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        if let accessToken = self.authService.currentAccessToken?.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
