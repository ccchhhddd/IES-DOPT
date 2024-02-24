interface UserModel extends Auth.UserInfo {
  token: string;
  refreshToken: string;
  password: string;
}

export const userModel: UserModel[] = [

  {
    token: '__TOKEN_SOYBEAN__',
    refreshToken: '__REFRESH_TOKEN_SOYBEAN__',
    userId: '0',
    userName: 'chd',
    userRole: 'super',
    password: 'chd2216113771'
  },
  {
    token: '__TOKEN_SUPER__',
    refreshToken: '__REFRESH_TOKEN_SUPER__',
    userId: '1',
    userName: 'wcc',
    userRole: 'super',
    password: 'wcc2213411885'
  },
	{
    token: '__TOKEN_ADMIN__',
    refreshToken: '__REFRESH_TOKEN_ADMIN__',
    userId: '2',
    userName: 'bhy',
    userRole: 'super',
    password: 'bhy2206114209'
  },
  {
    token: '__TOKEN_ADMIN__',
    refreshToken: '__REFRESH_TOKEN_ADMIN__',
    userId: '3',
    userName: 'sxy',
    userRole: 'super',
    password: 'sxy2213722780'
  },
  {
    token: '__TOKEN_USER01__',
    refreshToken: '__REFRESH_TOKEN_USER01__',
    userId: '4',
    userName: 'zbq',
    userRole: 'super',
    password: 'zbq2216113096'
  },
	{
    token: '__TOKEN_USER01__',
    refreshToken: '__REFRESH_TOKEN_USER01__',
    userId: '5',
    userName: 'szj',
    userRole: 'super',
    password: 'szj2211324610'
  },
	{
    token: '__TOKEN_USER01__',
    refreshToken: '__REFRESH_TOKEN_USER01__',
    userId: '6',
    userName: 'cyb',
    userRole: 'super',
    password: 'cyb2215015012'
  },
	{
    token: '__TOKEN_USER01__',
    refreshToken: '__REFRESH_TOKEN_USER01__',
    userId: '7',
    userName: 'yyh',
    userRole: 'super',
    password: 'yyh2223322279'
  },
];
