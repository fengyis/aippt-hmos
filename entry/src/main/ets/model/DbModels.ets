@ObservedV2
export class PPTCreateTable {
  @Trace id: number = 0
  @Trace taskId: string = ''
  @Trace title: string = ''
  @Trace status: string = ''
  @Trace fileUrl: string = ''
  @Trace createTime: number = 0
  @Trace coverImgSrc: string = ''
  @Trace templateIndexId: string = ''
  @Trace isSelected: boolean = false

  getFormatTime(): string {
    const d = new Date(this.createTime)
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`
  }
}

@ObservedV2
export class PPTCollectTable {
  @Trace templateId: string = ''
  @Trace coverUrl: string = ''
  @Trace title: string = ''
  @Trace collectTime: number = 0
  @Trace templateName: string = ''
}

export class PPTCreateRecord {
  id: number = 0
  taskId: string = ''
  title: string = ''
  status: string = ''
  fileUrl: string = ''
  createTime: number = 0
}
