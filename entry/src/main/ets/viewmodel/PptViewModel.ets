import { PptTemplateBean, PptChapter, PptOutLineData, PptProgressData, PptResultData } from '../model/PptModels'
import { PptApiService } from '../service/PptApiService'

@ObservedV2
export class PptViewModel {
  @Trace templates: PptTemplateBean[] = []
  @Trace categories: string[] = []
  @Trace selectedTemplate: PptTemplateBean | null = null
  @Trace chapters: PptChapter[] = []
  @Trace outline: PptOutLineData | null = null
  @Trace isCreatingOutline: boolean = false
  @Trace isCreatingPpt: boolean = false
  @Trace progress: PptProgressData | null = null
  @Trace result: PptResultData | null = null
  @Trace searchKeyword: string = ''
  @Trace searchResults: PptTemplateBean[] = []
  @Trace from: string = ''
  @Trace query: string = ''
  @Trace errorMessage: string = ''
  @Trace isLoading: boolean = false

  private api: PptApiService = new PptApiService()

  async fetchTemplateList(): Promise<void> {
    this.isLoading = true
    try {
      const resp = await this.api.fetchTemplateList()
      if (resp.isSuccess() && resp.data) {
        this.templates = resp.data
      }
    } finally {
      this.isLoading = false
    }
  }

  async createOutline(query: string, filePath: string = ''): Promise<boolean> {
    this.isCreatingOutline = true
    try {
      const resp = filePath
        ? await this.api.createOutlineByFile(filePath)
        : await this.api.createOutlineByQuery(query)
      if (resp.isSuccess() && resp.data) {
        this.outline = resp.data
        this.chapters = resp.data.outline ?? []
        return true
      }
      this.errorMessage = resp.msg || '大纲生成失败'
      return false
    } finally {
      this.isCreatingOutline = false
    }
  }

  async createPpt(): Promise<void> {
    if (!this.outline || !this.selectedTemplate) return
    this.isCreatingPpt = true
    try {
      const resp = await this.api.createPptByOutline(
        this.query, this.outline.sid, {}, this.selectedTemplate.templateIndexId
      )
      if (resp.isSuccess() && resp.data) {
        this.result = resp.data
      }
    } finally {
      this.isCreatingPpt = false
    }
  }

  async queryProgress(): Promise<void> {
    if (!this.outline) return
    const resp = await this.api.queryProgress(this.outline.sid)
    if (resp.isSuccess() && resp.data) {
      this.progress = resp.data
    }
  }

  filterKeyword(keyword: string): void {
    this.searchKeyword = keyword
    const kw = keyword.toLowerCase()
    this.searchResults = this.templates.filter(t => t.templateName.toLowerCase().includes(kw))
  }
}
