const optimization: AuthRoute.Route = {
  name: 'optimization',
  path: '/optimization',
  component: 'basic',
  meta: { title: 'optimization', icon: 'mdi:menu' },
  children: [
    {
      name: 'optimization_workbench',
      path: '/optimization/workbench',
      component: 'self',
      meta: { title: 'optimization_workbench', icon: 'mdi:menu' }
    },
    {
      name: 'optimization_analysis',
      path: '/optimization/analysis',
      component: 'self',
      meta: { title: 'optimization_analysis', icon: 'mdi:menu' }
    }
  ]
};

export default optimization;
