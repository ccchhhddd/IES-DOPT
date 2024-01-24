export const routeModel: Record<Auth.RoleType, AuthRoute.Route[]> = {
  super: [{
    name: 'dashboard',
    path: '/dashboard',
    component: 'basic',
    children: [
			{
        name: 'dashboard_analysis',
        path: '/dashboard/analysis',
        component: 'self',
        meta: {
          title: '蒸汽动力循环仿真',
          requiresAuth: true,
          icon: 'icon-park-outline:analysis'
        }
      },
      {
        name: 'dashboard_workbench',
        path: '/dashboard/workbench',
        component: 'self',
        meta: {
          title: '顺流与逆流式换热器',
          requiresAuth: true,
          icon: 'icon-park-outline:workbench',
        }
      },
			{
        name: 'dashboard_venturi',
        path: '/dashboard/venturi',
        component: 'self',
        meta: {
          title: '文丘里管压力仿真',
          requiresAuth: true,
          icon: 'icon-park-outline:workbench',
        }
      },
    ],
    meta: {
      title: '仿真',
      icon: 'mdi:monitor-dashboard',
      order: 1
    }
  },
	{
    name: 'controler',
    path: '/controler',
    component: 'basic',
    children: [

      {
        name: 'controler_scenario',
        path: '/controler/scenario',
        component: 'self',
        meta: {
          title: 'PID控制实验',
          requiresAuth: true,
          icon: 'icon-park-outline:editor',
        }
      }
    ],
    meta: {
      title: '控制',
      icon: 'mdi:monitor-dashboard',
      order: 2
    }
  }],
  admin: [],
  user: []
};
