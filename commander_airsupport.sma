/**

**/

enum _:lawsspr_e
{
	lawspr_smoke = 0,
	lawspr_smoke2,
	lawspr_smokespr,
	lawspr_smokespr2,
	lawspr_rocketexp,
	lawspr_rocketexp2,
	lawspr_smoketrail,
	lawspr_fire,
	lawspr_fire2,
	lawspr_fire3
};
new g_iLawsSprIndex[lawsspr_e];

new const g_rgszBreakModels[][] = { "models/gibs_wallbrown.mdl", "models/gibs_woodplank.mdl", "models/gibs_brickred.mdl" };
new g_rgiBreakModels[sizeof g_rgszBreakModels];

#define g_CvarFriendlyFire	get_cvar_num("mp_friendlyfire")

#define pev_fighterkey	pev_iuser2
#define pev_soundthink	pev_fuser1

#define RADIO_KEY	16486345

#define GROUP_OP_AND	0
#define GROUP_OP_NAND	1

#define ROCKET_GROUPINFO	(1<<10)
#define ROCKET_OFFSET		0.35

new g_strInfoTargetText, g_strSparkShowerText;
new gmsgScreenShake, gmsgScreenFade;

public AirSupport_Initialize()
{
	register_forward(FM_Touch, "fw_Missile_Touch_Post", 1);
	register_forward(FM_Think, "fw_Missile_Think_Post", 1);
	register_forward(FM_CheckVisibility, "fw_CheckVisibility");
	register_forward(FM_SetGroupMask, "fw_SetGroupMask_Post", 1);
	
	gmsgScreenFade = get_user_msgid("ScreenFade");
	gmsgScreenShake = get_user_msgid("ScreenShake");
}

public AirSupport_Precache()
{
	g_strInfoTargetText = engfunc(EngFunc_AllocString, "info_target");
	g_strSparkShowerText = engfunc(EngFunc_AllocString, "spark_shower");
	
	engfunc(EngFunc_PrecacheModel, "models/F18.mdl");
	
	for (new i = 0; i < sizeof g_rgszBreakModels; i ++)
		g_rgiBreakModels[i] = precache_model(g_rgszBreakModels[i]);
	
	engfunc(EngFunc_PrecacheSound, "weapons/law_travel.wav");
	
	static szName[64];
	for (new i = 1; i <= 6; i ++)
	{
		formatex(szName, charsmax(szName), "airsupport/explode/explode_near_%d.wav", i);
		precache_sound(szName);
	}
	
	for (new i = 1; i <= 12; i ++)
	{
		formatex(szName, charsmax(szName), "airsupport/jet/jet_short_%d.wav", i);
		precache_sound(szName);
	}
	
	g_iLawsSprIndex[lawspr_smokespr] = precache_model("sprites/exsmoke.spr");
	g_iLawsSprIndex[lawspr_smokespr2] = precache_model("sprites/rockeexfire.spr");
	g_iLawsSprIndex[lawspr_rocketexp] = precache_model("sprites/rockeexplode.spr");
	g_iLawsSprIndex[lawspr_rocketexp2] = precache_model("sprites/zerogxplode-big1.spr");
	g_iLawsSprIndex[lawspr_smoketrail] = precache_model("sprites/tdm_smoke.spr");
	g_iLawsSprIndex[lawspr_fire] = precache_model("sprites/rockefire.spr");
	g_iLawsSprIndex[lawspr_fire2] = precache_model("sprites/hotglow.spr");
	g_iLawsSprIndex[lawspr_fire3] = precache_model("sprites/flame.spr");
	g_iLawsSprIndex[lawspr_smoke] = precache_model("sprites/gas_smoke1.spr");
	g_iLawsSprIndex[lawspr_smoke2] = precache_model("sprites/wall_puff1.spr");
}

//public Call(id, iTeam, Float:vecSrc[3], Float:vecEnd[3], Float:vecReturn[3], const szModel[])
public Call(pPlayer, iTeam, Float:vecGoal[3])
{
	// determind the direction of the plane first.
	new trPlayer = create_tr2(), trGoal = create_tr2();
	new Float:vecPlayer[3], Float:vecPlayerSky[3], Float:vecGoalSky[3];
	
	// check player sky
	pev(pPlayer, pev_origin, vecPlayer);
	xs_vec_copy(vecPlayer, vecPlayerSky);
	vecPlayerSky[2] = 9999.0;
	engfunc(EngFunc_TraceLine, vecPlayer, vecPlayerSky, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, pPlayer, trPlayer);
	get_tr2(trPlayer, TR_vecEndPos, vecPlayerSky);
	
	if (engfunc(EngFunc_PointContents, vecPlayerSky) != CONTENTS_SKY)
	{
		free_tr2(trPlayer);
		free_tr2(trGoal);
		server_print("PLAYER NO SKY");
		return 0;
	}
	else
		vecPlayerSky[2] -= 2.0;
	
	// check goal sky
	xs_vec_copy(vecGoal, vecGoalSky);
	vecGoalSky[2] = 9999.0;
	engfunc(EngFunc_TraceLine, vecGoal, vecGoalSky, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, 0, trGoal);
	get_tr2(trGoal, TR_vecEndPos, vecGoalSky);
	
	if (engfunc(EngFunc_PointContents, vecGoalSky) != CONTENTS_SKY)
	{
		free_tr2(trPlayer);
		free_tr2(trGoal);
		server_print("GOAL NO SKY");
		return 0;
	}
	else
		vecGoalSky[2] -= 3.0;
	
	// even out the delta height
	vecPlayerSky[2] = floatmin(vecPlayerSky[2], vecGoalSky[2]);
	vecGoalSky[2] = vecPlayerSky[2];
	
	// create angle and velocity
	new Float:vecAngles[3], Float:vecVelocity[3];
	xs_vec_sub(vecGoalSky, vecPlayerSky, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	vector_to_angle(vecVelocity, vecAngles);
	xs_vec_mul_scalar(vecVelocity, 100.0, vecVelocity);
	
	new iFighter = engfunc(EngFunc_CreateNamedEntity, g_strInfoTargetText);
	engfunc(EngFunc_SetOrigin, iFighter, vecGoalSky);
	engfunc(EngFunc_SetModel, iFighter, "models/F18.mdl");
	engfunc(EngFunc_SetSize, iFighter, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	set_pev(iFighter, pev_classname, "fighter");
	set_pev(iFighter, pev_solid, SOLID_TRIGGER);
	set_pev(iFighter, pev_movetype, MOVETYPE_FLY);
	set_pev(iFighter, pev_angles, vecAngles);
	set_pev(iFighter, pev_v_angle, vecAngles);
	set_pev(iFighter, pev_velocity, vecVelocity);
	set_pev(iFighter, pev_fighterkey, RADIO_KEY);
	set_pev(iFighter, pev_groupinfo, ROCKET_GROUPINFO);
	set_pev(iFighter, pev_owner, pPlayer);
	
	new szName[64];
	formatex(szName, charsmax(szName), "airsupport/jet/jet_short_%d.wav", random_num(1, 12));
	client_cmd(0, "spk %s", szName);
	
	free_tr2(trPlayer);
	free_tr2(trGoal);
	return iFighter;
}

public Explosive(iAttacker, const Float:vecOrigin[3], Float:flRange, Float:flPunchMax, Float:flDamage, Float:flKnockForce)
{
	new id = -1, Float:flTakeDamage, szClassName[32], Float:vecOrigin2[3], Float:flDistance, Float:flRealDamage;
	
	while ((id = engfunc(EngFunc_FindEntityInSphere, id, vecOrigin, flRange)) > 0)
	{
		pev(id, pev_takedamage, flTakeDamage);
		if (flTakeDamage == DAMAGE_NO)
			continue;
		
		if (is_user_alive(id) && !g_CvarFriendlyFire && fm_is_user_same_team(iAttacker, id))
			continue;
		
		pev(id, pev_classname, szClassName, charsmax(szClassName));
		if (!strcmp(szClassName, "func_breakable") || !strcmp(szClassName, "func_pushable"))
		{
			dllfunc(DLLFunc_Use, iAttacker, id);
			continue;
		}
		
		pev(id, pev_origin, vecOrigin2);
		flDistance = get_distance_f(vecOrigin, vecOrigin2);
		flRealDamage = flDamage * ((flRange - flDistance) / flRange);
		
		if (flRealDamage <= 0.0)
			continue;
		
		if (UTIL_PointVisible(vecOrigin, vecOrigin2, _, id))
			flRealDamage *= random_float(0.4, 0.5);
		
		ExecuteHamB(Ham_TakeDamage, id, 0, iAttacker, flRealDamage, DMG_BLAST);
		
		if (!is_user_alive(id))
			continue;
		
		emessage_begin(MSG_ONE_UNRELIABLE, gmsgScreenShake, _, id);
		ewrite_short(1<<13);
		ewrite_short(1<<13);
		ewrite_short(1<<13);
		emessage_end();
		
		emessage_begin(MSG_ONE_UNRELIABLE, gmsgScreenFade, _, id);
		ewrite_short(1<<10);
		ewrite_short(0);
		ewrite_short(0x0000);
		ewrite_byte(255);
		ewrite_byte(255);
		ewrite_byte(255);
		ewrite_byte(255);
		emessage_end();
		
		new Float:vecPunchAngle[3];
		vecPunchAngle[0] = random_float(-flPunchMax, flPunchMax)
		vecPunchAngle[1] = random_float(-flPunchMax, flPunchMax)
		vecPunchAngle[2] = random_float(-flPunchMax, flPunchMax)
		set_pev(id, pev_punchangle, vecPunchAngle)
		
		new Float:vecVelocity[3], Float:flSpeed;
		xs_vec_sub(vecOrigin2, vecOrigin, vecVelocity);								// 创造一个向量, 方向指向受害者的点。(计算时需要将受害者的坐标减去爆炸中心)
		xs_vec_normalize(vecVelocity, vecVelocity);									// 修正此向量为单位向量
		flSpeed = floatpower(flKnockForce, (flRange - flDistance) / flRange);		// 以指数衰减定义冲击波
		xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);						// 向量数乘, 将速率转为速度
		vecVelocity[2] += flKnockForce * random_float(0.35, 0.45);					// 强化竖直方向上的速度
		set_pev(id, pev_velocity, vecVelocity);										// 给受害者设置计算完毕的速度(即击退)
	}
}

public Effect(Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 200.0);
	write_short(g_iLawsSprIndex[lawspr_rocketexp]);
	write_byte(20);
	write_byte(100);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 70.0);
	write_short(g_iLawsSprIndex[lawspr_rocketexp2]);
	write_byte(30);
	write_byte(255);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(engfunc(EngFunc_DecalIndex, "{scorch1"));
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(50);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	write_byte(2);
	write_byte(0);
	message_end();
	
	new Float:vecSrc[3], Float:vecEnd[3], Float:vecPlaneNormal[3];
	xs_vec_set(vecSrc, vecOrigin[0], vecOrigin[1], vecOrigin[2] + 9999.0);
	xs_vec_set(vecEnd, vecOrigin[0], vecOrigin[1], vecOrigin[2] - 9999.0);
	engfunc(EngFunc_TraceLine, vecOrigin, vecSrc, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_vecEndPos, vecSrc);
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
	
	new iEntity;
	for (new i = 0; i < 3; i ++)
	{
		iEntity = engfunc(EngFunc_CreateNamedEntity, g_strSparkShowerText);
		engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
		set_pev(iEntity, pev_angles, vecPlaneNormal);
		xs_vec_set(vecSrc, vecOrigin[0] + 1.0, vecOrigin[1] + 1.0, vecOrigin[2] + 1.0);
		xs_vec_set(vecEnd, vecOrigin[0] - 1.0, vecOrigin[1] - 1.0, vecOrigin[2] - 1.0);
		set_pev(iEntity, pev_absmin, vecEnd);
		set_pev(iEntity, pev_absmax, vecSrc);
		dllfunc(DLLFunc_Spawn, iEntity);
	}
	
	if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER)
		return;
	
	vecOrigin[2] += 40.0;
	
	new Float:vecOrigin2[8][3], Float:vecOrigin3[21][3], Float:vecPosition[3];
	xs_vec_copy(vecOrigin, vecPosition);
	get_spherical_coord(vecPosition, 100.0, 20.0, 0.0, vecOrigin3[0]);
	get_spherical_coord(vecPosition, 0.0, 100.0, 0.0, vecOrigin3[1]);
	get_spherical_coord(vecPosition, 100.0, 100.0, 0.0, vecOrigin3[2]);
	get_spherical_coord(vecPosition, 70.0, 120.0, 0.0, vecOrigin3[3]);
	get_spherical_coord(vecPosition, 120.0, 20.0, 0.0, vecOrigin3[4]);
	get_spherical_coord(vecPosition, 120.0, 65.0, 0.0, vecOrigin3[5]);
	get_spherical_coord(vecPosition, 120.0, 110.0, 0.0, vecOrigin3[6]);
	get_spherical_coord(vecPosition, 120.0, 155.0, 0.0, vecOrigin3[7]);
	get_spherical_coord(vecPosition, 120.0, 200.0, 0.0, vecOrigin3[8]);
	get_spherical_coord(vecPosition, 120.0, 245.0, 0.0, vecOrigin3[9]);
	get_spherical_coord(vecPosition, 120.0, 290.0, 20.0, vecOrigin3[10]);
	get_spherical_coord(vecPosition, 120.0, 335.0, 20.0, vecOrigin3[11]);
	get_spherical_coord(vecPosition, 120.0, 40.0, 20.0, vecOrigin3[12]);
	get_spherical_coord(vecPosition, 40.0, 120.0, 20.0, vecOrigin3[13]);
	get_spherical_coord(vecPosition, 40.0, 110.0, 20.0, vecOrigin3[14]);
	get_spherical_coord(vecPosition, 60.0, 110.0, 20.0, vecOrigin3[15]);
	get_spherical_coord(vecPosition, 110.0, 40.0, 20.0, vecOrigin3[16]);
	get_spherical_coord(vecPosition, 120.0, 30.0, 20.0, vecOrigin3[17]);
	get_spherical_coord(vecPosition, 30.0, 130.0, 20.0, vecOrigin3[18]);
	get_spherical_coord(vecPosition, 30.0, 125.0, 20.0, vecOrigin3[19]);
	get_spherical_coord(vecPosition, 30.0, 120.0, 20.0, vecOrigin3[20]);
	
	for (new i = 0; i < 21; i++)
	{
		if (i < 8)
		{
			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_BREAKMODEL);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);
			engfunc(EngFunc_WriteCoord, vecOrigin[2]);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-300.0, 300.0));
			write_byte(10);
			write_short(g_rgiBreakModels[random_num(0, sizeof g_rgszBreakModels - 1)]);
			write_byte(random_num(1, 4));
			write_byte(random_num(4, 8) * 10);
			write_byte(0x40);
			message_end();
		}
		
		MakeSmoke(vecOrigin3[i], g_iLawsSprIndex[lawspr_smokespr2], 10, 255);
	}
	
	vecOrigin[2] += 120.0;

	get_spherical_coord(vecOrigin, 0.0, 0.0, 185.0, vecOrigin2[0]);
	get_spherical_coord(vecOrigin, 0.0, 80.0, 130.0, vecOrigin2[1]);
	get_spherical_coord(vecOrigin, 41.0, 43.0, 110.0, vecOrigin2[2]);
	get_spherical_coord(vecOrigin, 90.0, 90.0, 90.0, vecOrigin2[3]);
	get_spherical_coord(vecOrigin, 80.0, 25.0, 185.0, vecOrigin2[4]);
	get_spherical_coord(vecOrigin, 101.0, 100.0, 162.0, vecOrigin2[5]);
	get_spherical_coord(vecOrigin, 68.0, 35.0, 189.0, vecOrigin2[6]);
	get_spherical_coord(vecOrigin, 0.0, 95.0, 155.0, vecOrigin2[7]);
	
	for (new i = 0; i < 8; i++)
		MakeSmoke(vecOrigin2[i], g_iLawsSprIndex[lawspr_smoke], 50, 50);
}

public Launch(id, const Float:vecSrc[3], const Float:vecEnd[3])
{
	new Float:vecTemp[3], Float:vecAngles[3];
	xs_vec_sub(vecEnd, vecSrc, vecTemp);
	xs_vec_normalize(vecTemp, vecTemp);
	xs_vec_mul_scalar(vecTemp, 1000.0, vecTemp);
	vector_to_angle(vecTemp, vecAngles);
	
	new iEntity = engfunc(EngFunc_CreateNamedEntity, g_strInfoTargetText);
	engfunc(EngFunc_SetOrigin, iEntity, vecSrc);
	engfunc(EngFunc_SetModel, iEntity, "models/mq9_missile.mdl");
	engfunc(EngFunc_SetSize, iEntity, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	set_pev(iEntity, pev_classname, "rpgrocket");
	set_pev(iEntity, pev_owner, id);
	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_gravity, 1.0);
	set_pev(iEntity, pev_angles, vecAngles);
	vecAngles[0] *= -1.0;	// 这就是vangle和angles的换算 -3.0
	set_pev(iEntity, pev_v_angle, vecAngles);
	set_pev(iEntity, pev_velocity, vecTemp);
	set_pev(iEntity, pev_groupinfo, ROCKET_GROUPINFO);
	fw_Missile_Think_Post(iEntity);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecSrc[0]);
	engfunc(EngFunc_WriteCoord, vecSrc[1]);
	engfunc(EngFunc_WriteCoord, vecSrc[2]);
	write_short(g_iLawsSprIndex[lawspr_fire]);
	write_byte(5);
	write_byte(255);
	message_end();
	
	set_pev(iEntity, pev_effects, EF_LIGHT | EF_BRIGHTLIGHT);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(g_iLawsSprIndex[lawspr_smoketrail]);
	write_byte(floatround(1000.0/100.0));
	write_byte(3);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();
	
	new Float:vecOrigin[5][3];
	get_spherical_coord(vecSrc, 20.0, 30.0, 5.0, vecOrigin[0]);
	get_spherical_coord(vecSrc, 20.0, -20.0, -5.0, vecOrigin[1]);
	get_spherical_coord(vecSrc, -14.0, 30.0, 7.0, vecOrigin[2]);
	get_spherical_coord(vecSrc, 25.0, 10.0, -8.0, vecOrigin[3]);
	get_spherical_coord(vecSrc, -17.0, 17.0, 0.0, vecOrigin[4]);
	
	for (new i = 0; i < 5; i++)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][2]);
		write_short(g_iLawsSprIndex[lawspr_smokespr]);
		write_byte(10);
		write_byte(50);
		message_end();
	}
}

public fw_Missile_Think_Post(iEntity)
{
	if (pev_valid(iEntity) != 2)
		return;
	
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	
	if (!strcmp(szClassName, "rpgrocket"))
	{
		set_pev(iEntity, pev_nextthink, get_gametime() + random_float(0.015, 0.05));
		
		static Float:fCurTime, Float:fUser1;
		global_get(glb_time, fCurTime);
		pev(iEntity, pev_soundthink, fUser1);
		if (fUser1 <= fCurTime)
		{
			set_pev(iEntity, pev_soundthink, fCurTime + 1.0);
			emit_sound(iEntity, CHAN_WEAPON, "weapons/law_travel.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		
		static Float:vecAngles[3];
		pev(iEntity, pev_v_angle, vecAngles);
		vecAngles[0] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		vecAngles[1] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		vecAngles[2] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		set_pev(iEntity, pev_v_angle, vecAngles);
		
		static Float:vecVelocity[3];
		velocity_by_aim(iEntity, 1000, vecVelocity);
		set_pev(iEntity, pev_velocity, vecVelocity);
		vector_to_angle(vecVelocity, vecAngles);
		set_pev(iEntity, pev_angles, vecAngles);
		
		static Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		get_aim_origin_vector(iEntity, -100.0, 1.0, 5.0, vecOrigin);
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iLawsSprIndex[lawspr_fire2]);
		write_byte(3);
		write_byte(255);
		message_end();
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iLawsSprIndex[random_num(lawspr_smoke, lawspr_smokespr)]);
		write_byte(random_num(1, 10));
		write_byte(random_num(50, 255));
		message_end();
	}
}

public fw_Missile_Touch_Post(iEntity, iPtd)
{
	if (pev(iEntity, pev_fighterkey) == RADIO_KEY && pev_valid(iPtd) != 2)
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
		return;
	}
	
	static szClassName[64];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	
	if (!strcmp(szClassName, "rpgrocket"))
	{
		new Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			engfunc(EngFunc_RemoveEntity, iEntity);
			return;
		}
		
		new id = pev(iEntity, pev_owner);
		RandomExplosionSound(iEntity);
		Explosive(id, vecOrigin, 350.0, 8.0, 275.0, 600.0);
		Effect(vecOrigin);
		
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}

public fw_CheckVisibility(iEntity, pSetPVS)
{
	if (pev(iEntity, pev_fighterkey) == RADIO_KEY)
	{
		forward_return(FMV_CELL, true);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_SetGroupMask_Post(iMask, iOperation)
{
	engfunc(EngFunc_SetGroupMask, ROCKET_GROUPINFO, GROUP_OP_NAND);
}

stock RandomExplosionSound(iEntity)
{
	new szName[64];
	formatex(szName, charsmax(szName), "airsupport/explode/explode_near_%d.wav", random_num(1, 6));
	emit_sound(iEntity, CHAN_WEAPON, szName, 1.0, 0.3, 0, PITCH_NORM);
}

stock MakeSmoke(const Float:position[3], sprite_index, size, light)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, position, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, position[0])
	engfunc(EngFunc_WriteCoord, position[1])
	engfunc(EngFunc_WriteCoord, position[2])
	write_short(sprite_index)
	write_byte(size)
	write_byte(light)
	message_end()
}

