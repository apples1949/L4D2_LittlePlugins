/**
* @Author 夜羽真白
* @Date 2023-07-28 13:25:47
* @Description 时钟回调部分
* @Version 1.0.0.0
* @GitHub https://github.com/GlowingTree880/L4D2_LittlePlugins
**/

#pragma semicolon 1
#pragma newdecls required

// HACK: 基准时钟回调, 固定时钟回调, 动态时钟回调完善, Bug 发现处理
/**
* 基准刷特时钟回调
* @param timer 时钟句柄
* @return Action
**/
public Action timerStandardInfectedSpawnHandler(Handle timer) {
	if (!isLeftSafeArea) {
		standardInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}

	log.debugAndInfo("\n%s: 基准时钟触发, 当前记录波次 %d, 距离上一波刷特完成经过 %.3f s\n", PLUGIN_PREFIX, standardInfectedSpawnTimer.recordSpawnWaveCount, GetEngineTime() - spawnInterval);

	// 如果在一次找位刷新失败后的延迟时间, 触发了任何刷新时钟, 或 正在刷特中 都不允许刷新下一波
	if (isInFindPosFailedDelay || canSpawnNewInfected) {
		log.debugAndInfo("%s: 当前正在一次找位失败后延迟时间或正在刷新特感, 不处理基准时钟逻辑", PLUGIN_PREFIX);

		standardInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}
	if (regularInfectedSpawnTimer.timer != null) {
		log.debugAndInfo("%s: 当前固定时钟不为 null, 固定时钟下次触发慢于基准时钟, 删除固定时钟", PLUGIN_PREFIX);
		delete regularInfectedSpawnTimer.timer;
	}
	if (autoInfectedSpawnTimer.timer != null) {
		log.debugAndInfo("%s: 当前动态时钟不为 null, 动态时钟下次触发慢于基准时钟, 删除动态时钟", PLUGIN_PREFIX);
		delete autoInfectedSpawnTimer.timer;
	}

	// 如果基准时钟还没有被触发, 则设置触发状态为 true 已触发
	if (!standardInfectedSpawnTimer.isTriggered)
		standardInfectedSpawnTimer.isTriggered = true;
	// 基准时钟触发次数自增
	standardInfectedSpawnTimer.lastTriggerTime = GetGameTime();
	standardInfectedSpawnTimer.recordSpawnWaveCount++;
	standardInfectedSpawnTimer.triggerCount++;
	// 可以使用基准时钟刷新新一波特感
	canSpawnNewInfected = true;
	isInSpawnFinishedTime = false;
	// 如果有跑男则以跑男找位
	checkRunnerExistAndStartHook();

	log.debugAndInfo("%s: 基准时钟允许刷新新一波特感, 当前基准时钟记录波次 %d", PLUGIN_PREFIX, standardInfectedSpawnTimer.recordSpawnWaveCount);
	// 基准时钟本次触发结束, 置 null 返回
	standardInfectedSpawnTimer.timer = null;
	return Plugin_Stop;
}

/**
* 固定刷特时钟回调
* @param timer 时钟句柄
* @return Action
**/
public Action timerRegularInfectedSpawnHandler(Handle timer) {
	if (!isLeftSafeArea) {
		regularInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}
	log.debugAndInfo("\n%s: 固定时钟触发, 当前记录波次 %d, 距离上一波刷特完成经过 %.3f s, 距离上次创建固定时钟经过 %.3f s\n", PLUGIN_PREFIX, regularInfectedSpawnTimer.recordSpawnWaveCount, GetEngineTime() - spawnInterval, GetEngineTime() - regularTimerCreatedTime);

	if (isInFindPosFailedDelay || canSpawnNewInfected) {
		log.debugAndInfo("%s: 当前正在一次找位失败后延迟时间或正在刷新特感, 不处理固定时钟逻辑", PLUGIN_PREFIX);

		regularInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}
	// 基准时钟只可能与固定时钟或动态时钟的一种并存, 因此固定时钟中不需要判断动态时钟, 只需要判断基准时钟即可
	if (standardInfectedSpawnTimer.timer != null) {
		log.debugAndInfo("%s: 当前基准时钟不为 null, 基准时钟下次触发慢于固定时钟, 删除基准时钟", PLUGIN_PREFIX);
		delete standardInfectedSpawnTimer.timer;
	}

	if (!regularInfectedSpawnTimer.isTriggered)
		regularInfectedSpawnTimer.isTriggered = true;

	regularInfectedSpawnTimer.lastTriggerTime = GetGameTime();
	regularInfectedSpawnTimer.recordSpawnWaveCount++;
	regularInfectedSpawnTimer.triggerCount++;

	canSpawnNewInfected = true;
	isInSpawnFinishedTime = false;

	checkRunnerExistAndStartHook();

	log.debugAndInfo("%s: 固定时钟允许刷新新一波特感, 当前固定时钟记录波次 %d", PLUGIN_PREFIX, regularInfectedSpawnTimer.recordSpawnWaveCount);

	regularInfectedSpawnTimer.timer = null;
	return Plugin_Stop;
}

/**
* 动态刷特时钟回调
* @param timer 时钟句柄
* @return Action
**/
public Action timerAutoInfectedSpawnHandler(Handle timer) {
	if (!isLeftSafeArea) {
		autoInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}
	log.debugAndInfo("\n%s: 动态时钟触发, 当前记录波次 %d, 距离上一波刷特完成经过 %.3f s, 距离上次创建动态时钟经过 %.3f s\n", PLUGIN_PREFIX, autoInfectedSpawnTimer.recordSpawnWaveCount, GetEngineTime() - spawnInterval, GetEngineTime() - autoTimerCreatedTime);

	if (isInFindPosFailedDelay || canSpawnNewInfected) {
		log.debugAndInfo("%s: 当前正在一次找位失败后延迟时间或正在刷新特感, 不处理动态时钟逻辑", PLUGIN_PREFIX);

		autoInfectedSpawnTimer.timer = null;
		return Plugin_Stop;
	}
	if (standardInfectedSpawnTimer.timer != null) {
		log.debugAndInfo("%s: 当前基准时钟不为 null, 基准时钟下次触发慢于动态时钟, 删除基准时钟", PLUGIN_PREFIX);
		delete standardInfectedSpawnTimer.timer;
	}

	// 如果动态时钟没有触发过, 则设置触发位为 true
	if (!autoInfectedSpawnTimer.isTriggered)
		autoInfectedSpawnTimer.isTriggered = true;

	autoInfectedSpawnTimer.lastTriggerTime = GetGameTime();
	autoInfectedSpawnTimer.recordSpawnWaveCount++;
	autoInfectedSpawnTimer.triggerCount++;

	canSpawnNewInfected = true;
	isInSpawnFinishedTime = false;

	checkRunnerExistAndStartHook();

	log.debugAndInfo("%s: 动态时钟允许刷新新一波特感, 当前动态时钟记录波次 %d", PLUGIN_PREFIX, autoInfectedSpawnTimer.recordSpawnWaveCount);
	
	autoInfectedSpawnTimer.timer = null;
	return Plugin_Stop;
}

/**
* 第一波特感刷新队列生成完成时钟回调
* @param timer 当前时钟句柄
* @return Action
**/
public Action timerGetFirstWaveInfectedQueue(Handle timer) {
	delete infectedQueue;
	infectedQueue = getInfectedQueue();
	
	// 获取队列时出错, 返回 null 或 设定特感数量不为 0 队列长度却小于 1
	if (infectedQueue == null || (g_hInfectedLimit.IntValue > 0 && infectedQueue.Length < 1)) {
		log.error("%s: 获取第一波特感刷新队列时发生错误, 当前队列是否为 null, 当前队列长度: %d", PLUGIN_PREFIX, infectedQueue == null, infectedQueue == null ? 0 : infectedQueue.Length);
		return Plugin_Stop;
	}

	// FIXED: 没办法传 ArrayList 引用 (2023-08-30)
	Call_StartForward(onFirstWaveInfectedQueueGenerated);
	Call_PushCell(infectedQueue);
	Call_Finish();

	return Plugin_Continue;
}

/**
* 设置 z_max_player_zombie 时钟回调
* @param timer 当前时钟句柄
* @return Action
**/
public Action timerSetMaxSpecialHandler(Handle timer) {
	if (game_zMaxPlayerZombie) {
		game_zMaxPlayerZombie.SetInt(g_hInfectedLimit.IntValue);
		
		log.debugAndInfo("%s: 将 z_max_player_zombie 数量设置为 %d", PLUGIN_PREFIX, g_hInfectedLimit.IntValue);
	}
	return Plugin_Continue;
}

/**
* 一次找位刷新失败且等待完暂停时间后重启这一波刷特时钟回调
* @param timer 当前时钟句柄
* @return Action
**/
public Action timerFindPosFailedHandler(Handle timer) {
	if (isInFindPosFailedDelay) {
		isInFindPosFailedDelay = false;
		canSpawnNewInfected = true;
	}
	return Plugin_Continue;
}

/**
* 第一波特感需要延迟刷新时钟回调
* @param timer 当前时钟句柄
* @return Action
**/
public Action timerFirstWaveDelaySpawnHandler(Handle timer) {
	canSpawnNewInfected = true;
	return Plugin_Continue;
}

public Action timerKickDeadInfectedHandler(Handle timer, int client) {
	if (!IsValidClient(client) || GetClientTeam(client) != TEAM_INFECTED || !IsFakeClient(client) || IsClientInKickQueue(client)) {
		return Plugin_Stop;
	}
	KickClient(client, "%s: 踢出死亡 Bot 特感", PLUGIN_PREFIX);
	return Plugin_Continue;
}

/**
* 分散刷新模式下某特感重生完成时钟回调
* @param timer 当前时钟句柄
* @param infectedType 当前重生完成的特感类型
* @return Action
**/
public Action timerRespawnFinishHandler(Handle timer, int client) {
	if (!isLeftSafeArea || !infectedStates[client].valid) {
		infectedStates[client].timer = null;
		return Plugin_Stop;
	}

	InfectedState state;
	state = infectedStates[client];

	log.debugAndInfo("\n%s: 索引 %d, %s [类型 %s] 重生完毕, 上次死亡时间为 %.2f, 距离上次死亡经过 %.3f s, 当前是否可以刷新特感 %b\n", PLUGIN_PREFIX, client, state.name, INFECTED_NAME[state.infectedType], state.deathTime, GetGameTime() - state.deathTime, canSpawnNewInfected);

	static int infectedType;
	infectedType = state.infectedType;
	if (infectedType < ZC_SMOKER || infectedType > ZC_CHARGER) {
		infectedStates[client].timer = null;
		return Plugin_Stop;
	}

	infectedStates[client].isRespawnFinished = true;
	respawnFinishedCount++;

	if (g_hSpawnMethodStrategy.IntValue == SMS_DISPERSE && currentSpawnWaveCount > 1) {
		int infectedCount = getTeamClientCount(TEAM_INFECTED, true, false);
		log.debugAndInfo("%s: 当前在场特感 %d 只, 复活完成 %d 只, 目标数量 %d 只", PLUGIN_PREFIX, infectedCount, respawnFinishedCount, targetCount);
		if (infectedCount + respawnFinishedCount < targetCount) {
			log.debugAndInfo("%s: 当前在场特感与重生完成特感数量相加为 %d 只, 少于目标数量 %d 只, 不允许复活", PLUGIN_PREFIX, infectedCount + respawnFinishedCount, targetCount);
			infectedStates[client].timer = null;
			return Plugin_Stop;
		}
	}

	// 跑男检测
	checkRunnerExistAndStartHook();

	if (!canSpawnNewInfected) {
		log.debugAndInfo("%s: 开始重生完成特感的刷新, 置 canSpawnNewInfected 为 true, isInSpawFinishedTime 为 false", PLUGIN_PREFIX);
		canSpawnNewInfected = true;
		isInSpawnFinishedTime = false;
		// 开始刷新前, 重置找位消耗时间
		findPosSpawnTimeCost = 0.0;
	}

	infectedStates[client].timer = null;
	return Plugin_Stop;
}

/**
* 跑男检测
* @param void
* @return int
**/
stock int doCheckRunnerExist() {
	static int targetClient, survivorCount;
	survivorCount = getTeamClientCount(TEAM_SURVIVOR, true, false);
	static float targetDensity, limitDensity;
	if (g_hRunnerCheckDistance.BoolValue && survivorCount > 1) {
		targetClient = L4D_GetHighestFlowSurvivor();
 		if (!IsValidClient(targetClient) || !IsPlayerAlive(targetClient)) {
			return INVALID_CLIENT_INDEX;
		}
		targetDensity = getSurvivorDensity(targetClient);
		limitDensity = 1.0 / float(survivorCount);
		if (FloatCompare(targetDensity, limitDensity) < 0) {
			log.debugAndInfo("%s: 找到跑男玩家: %N, 该玩家的生还者密度为 %.2f, 小于限制密度 %.2f", PLUGIN_PREFIX, targetClient, targetDensity, limitDensity);

			return targetClient;
		}
	}
	return INVALID_CLIENT_INDEX;
}

void checkRunnerExistAndStartHook() {
	static int runner;
	runner = doCheckRunnerExist();
	if (IsValidSurvivor(runner) && IsPlayerAlive(runner)) {
		// 找到了跑男玩家, 设置跑男玩家索引
		runnerIndex = runner;
		log.debugAndInfo("%s: 找到了跑男玩家 %N 即将针对其进行特感找位刷新", PLUGIN_PREFIX, runner);
		return;
	}
	// 如果没有跑男, 且是针对某个生还者找位, 则随机选择一个生还者
	if (g_hFindPosStrategy.IntValue == FPS_RANDOM_SURVIVOR) {
		targetIndex = getRandomSurvivor();
		if (IsValidSurvivor(targetIndex) && IsPlayerAlive(targetIndex))
			log.debugAndInfo("%s: 当前找位策略为针对某个生还者找位, 没有找到跑男玩家, 随机选择一个生还者 %N 进行特感找位刷新", PLUGIN_PREFIX, targetIndex);
		else
			log.debugAndInfo("%s: 当前找位策略为针对某个生还者找位, 没有找到跑男玩家, 随机选择一个生还者 %d 无效, 将针对所有人找位", PLUGIN_PREFIX, targetIndex);
	}
}