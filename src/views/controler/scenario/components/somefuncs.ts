import type { HandleElement } from "@vue-flow/core"

// 判定是否无效连接
function isValidConnection(conn:any, getNodes:any) {
  	// 先判断终点
  	let id = conn.target
  	let id_h = conn.targetHandle
  	let ids = [] as HandleElement[]
	let flag = false
	for (const i of getNodes) {
		if (id === i.id) {
			ids = i.handleBounds.target as HandleElement[]
			break
		}
	}
  	for (const j of ids) {
    	if (id_h === j.id) {
      		flag = true
      		break
    	}
	}
  	// 再判断起点
  	id = conn.source
	id_h = conn.sourceHandle
	for (const i of getNodes) {
		if (id === i.id) {
			ids = i.handleBounds.source as HandleElement[]
			break
		}
	}
  	for (const j of ids) {
    	if (id_h === j.id) {
    		return flag
    	}
	}
  	return false
}

export default isValidConnection