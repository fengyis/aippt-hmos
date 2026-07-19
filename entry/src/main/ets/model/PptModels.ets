@ObservedV2
export class PptTemplateBean {
  @Trace templateIndexId: string = ''
  @Trace templateName: string = ''
  @Trace coverUrl: string = ''
  @Trace category: string = ''
  @Trace tags: string[] = []
  @Trace colorScheme: string = ''
  @Trace isCollected: boolean = false
  @Trace detailImageBean: DetailImageBean | null = null

  getCoverList(): string[] {
    return this.detailImageBean?.coverList ?? []
  }

  static fromJson(json: Record<string, Object>): PptTemplateBean {
    const b = new PptTemplateBean()
    b.templateIndexId = (json['templateIndexId'] as string) ?? ''
    b.templateName = (json['templateName'] as string) ?? ''
    b.coverUrl = (json['coverUrl'] as string) ?? ''
    b.category = (json['category'] as string) ?? ''
    b.tags = (json['tags'] as string[]) ?? []
    b.colorScheme = (json['colorScheme'] as string) ?? ''
    return b
  }
}

@ObservedV2
export class DetailImageBean {
  @Trace titleCoverImage: string = ''
  @Trace coverList: string[] = []
}

@ObservedV2
export class PptChapter {
  @Trace chapterId: string = ''
  @Trace chapterTitle: string = ''
  @Trace chapterContents: PptChapter[] | null = null
  @Trace order: number = 0
}

@ObservedV2
export class PptOutLineData {
  @Trace sid: string = ''
  @Trace outline: PptChapter[] | null = null
}

@ObservedV2
export class PptProgressData {
  @Trace taskId: string = ''
  @Trace status: string = 'pending'
  @Trace progress: number = 0
}

@ObservedV2
export class PptResultData {
  @Trace fileUrl: string = ''
  @Trace previewUrl: string = ''
  @Trace pageCount: number = 0
  @Trace fileSize: number = 0
}
