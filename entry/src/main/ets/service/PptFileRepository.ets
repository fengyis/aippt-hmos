import { HttpClient } from '../network/HttpClient'
import { BaseResponse } from '../model/BaseResponse'

export class PptFileRepository {
  private client = HttpClient.getInstance()

  async downloadPptFile(taskId: string): Promise<BaseResponse<string>> {
    return this.client.get<string>(`/ppt/download?sid=${taskId}`)
  }

  async saveToLocal(sandboxPath: string): Promise<void> {
    // Save: fileIo.copyFile to sandbox path via DocumentViewPicker
  }

  async shareFile(filePath: string): Promise<void> {
    // Share: systemShare.share via @kit.ShareKit
  }
}
