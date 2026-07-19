import { http } from '@kit.NetworkKit'
import { HttpClient } from '../network/HttpClient'
import { BaseResponse } from '../model/BaseResponse'
import { PptTemplateBean, PptOutLineData, PptProgressData, PptResultData } from '../model/PptModels'

const PPT_BASE_URL = 'https://zwapi.xfyun.cn'

export class PptApiService {
  private client: HttpClient

  constructor() {
    this.client = HttpClient.getInstance()
    this.client.setBaseUrl(PPT_BASE_URL)
  }

  async fetchTemplateList(): Promise<BaseResponse<PptTemplateBean[]>> {
    return this.client.post<PptTemplateBean[]>('/api/ppt/v2/template/list')
  }

  async createOutlineByQuery(query: string): Promise<BaseResponse<PptOutLineData>> {
    return this.client.post<PptOutLineData>('/api/ppt/v2/createOutline', { query: query })
  }

  async createOutlineByFile(filePath: string): Promise<BaseResponse<PptOutLineData>> {
    return this.client.post<PptOutLineData>('/api/ppt/v2/createOutlineByDoc', { filePath: filePath })
  }

  async createPptByOutline(query: string, outlineSid: string, outline: Object, templateId: string): Promise<BaseResponse<PptResultData>> {
    return this.client.post<PptResultData>('/api/ppt/v2/createPptByOutline', {
      query: query,
      outlineSid: outlineSid,
      outline: outline,
      templateId: templateId
    })
  }

  async queryProgress(sid: string): Promise<BaseResponse<PptProgressData>> {
    return this.client.get<PptProgressData>(`/api/ppt/v2/progress?sid=${sid}`)
  }
}
