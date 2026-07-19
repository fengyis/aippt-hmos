import { HttpClient } from '../network/HttpClient'
import { BaseResponse } from '../model/BaseResponse'

export class PptFileRepository {
  private client = HttpClient.getInstance()

  async downloadPptFile(taskId: string): Promise<BaseResponse<string>> {
    return this.client.get<string>(`/ppt/download?sid=${taskId}`)
  }

  async saveToLocal(sandboxPath: string): Promise<void> {
    // FWD-REF: P-S04-011 resolve_by=Slice 4 Step 3c — fileIo.copyFile + picker.save()
  }

  async shareFile(filePath: string): Promise<void> {
    // FWD-REF: P-S04-012 resolve_by=Slice 4 Step 3c — systemShare.share()
  }
}
