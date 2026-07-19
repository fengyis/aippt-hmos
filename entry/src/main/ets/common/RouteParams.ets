export class SplashParams {
  hotLaunch: boolean = false
}

export class LoginParams {
  fromGuide: boolean = false
}

export class AccountInfoParams {
  userId: string = ''
}

export class MemberCenterParams {
  payFrom: string = ''
}

export class CreateOutlineParams {
  query: string = ''
  filePath: string = ''
  from: string = ''
  pptTemplateBeanJson: string = ''
}

export class PPTFileParams {
  pptCreateTableJson: string = ''
  isFromWorksPage: boolean = false
}

export class PPTTemplatePreviewParams {
  jsonStr: string = ''
  outlineJson: string = ''
  query: string = ''
  from: string = ''
}

export class RefundProgressParams {
  operateType: number = 0
  renewId: string = ''
  reason: string = ''
}

export class WorksPageParams {
  type: number = 1
}

export class NoParam {}
