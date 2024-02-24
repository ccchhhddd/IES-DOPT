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
          icon: 'icon-park:ripple'
        }
      },
      {
        name: 'dashboard_workbench',
        path: '/dashboard/workbench',
        component: 'self',
        meta: {
          title: '顺流与逆流式换热器',
          requiresAuth: true,
          icon: 'icon-park-outline:water',
        }
      },
			{
        name: 'dashboard_venturi',
        path: '/dashboard/venturi',
        component: 'self',
        meta: {
          title: '文丘里管压力仿真',
          requiresAuth: true,
          icon: 'icon-park-outline:process-line',
        }
      },
			{
        name: 'dashboard_scenario',
        path: '/dashboard/scenario',
        component: 'self',
        meta: {
          title: 'PID控制实验',
          requiresAuth: true,
          icon: 'icon-park:chart-line',
        }
      }
    ],
    meta: {
      title: '静态仿真',
      icon: 'icon-park:sphere',
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
          title: 'Jumulink',
          requiresAuth: true,
          icon: 'icon-park-outline:right-branch-one'
        }
      },
    ],
    meta: {
      title: '动态仿真',
      icon: 'icon-park-outline:triangle-ruler',
      order: 2
    }
  },
	{
    name: 'optimization',
    path: '/optimization',
    component: 'basic',
    children: [
			{
        name: 'optimization_workbench',
        path: '/optimization/workbench',
        component: 'self',
        meta: {
          title: '制氢能源系统',
          requiresAuth: true,
          icon: 'icon-park:h2'
        }
      },
    ],
    meta: {
      title: '优化',
      icon: 'icon-park:smart-optimization',
      order: 3
    }
  },

	],
  admin: [],
  user: []
};
