import { PptTemplateBean, PptChapter, PptOutLineData, PptProgressData, PptResultData } from '../model/PptModels'

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

  async fetchTemplateList(): Promise<void> {
    // FWD-REF: P-S04-008 resolve_by=Slice 4 Step 3c — PptApiService.fetchTemplateList()
  }

  async createOutline(query: string, filePath: string = ''): Promise<void> {
    this.isCreatingOutline = true
    // FWD-REF: P-S04-003 resolve_by=Slice 4 Step 3c — PptApiService.createOutlineByQuery(query)
  }

  filterKeyword(keyword: string): void {
    this.searchKeyword = keyword
    const kw = keyword.toLowerCase()
    this.searchResults = this.templates.filter(t => t.templateName.toLowerCase().includes(kw))
  }
}
