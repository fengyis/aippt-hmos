import { http } from '@kit.NetworkKit'
import { BaseResponse, ApiException } from '../model/BaseResponse'

const TAG = 'HttpClient'

export class HttpClient {
  private static instance: HttpClient
  private baseUrl: string = 'http://dev-api.whiap.cn'

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient()
    }
    return HttpClient.instance
  }

  setBaseUrl(url: string): void {
    this.baseUrl = url
  }

  async request<T>(method: http.RequestMethod, path: string, body?: Object): Promise<BaseResponse<T>> {
    const httpRequest = http.createHttp()
    try {
      const headers: Record<string, string> = {
        'Content-Type': 'application/json; charset=utf-8'
      }
      const token = this.getToken()
      if (token) {
        headers['token'] = token
      }

      const url = this.baseUrl + path
      const response = await httpRequest.request(url, {
        method: method,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined
      })

      const headerStr = JSON.stringify(response.header)
      const headerJson: Record<string, Object> = JSON.parse(headerStr) as Record<string, Object>

      const result = JSON.parse(response.result as string) as Record<string, Object>
      const code = result['code'] as number
      if (code !== 0) {
        throw new ApiException(code, result['msg'] as string ?? '')
      }
      return {
        code: code,
        msg: result['msg'] as string ?? '',
        data: result['data'] as T
      }
    } finally {
      httpRequest.destroy()
    }
  }

  async get<T>(path: string): Promise<BaseResponse<T>> {
    return this.request<T>(http.RequestMethod.GET, path)
  }

  async post<T>(path: string, body?: Object): Promise<BaseResponse<T>> {
    return this.request<T>(http.RequestMethod.POST, path, body)
  }

  private getToken(): string {
    return ''
  }
}
