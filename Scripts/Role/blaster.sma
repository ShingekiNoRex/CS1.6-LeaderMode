/**

**/

#define BLASTER_TEXT	g_rgszRoleNames[Role_Blaster]
#define BLASTER_TASK	5971543	// just some random number.

#define BLASTER_EXPLODE_SFX		"leadermode/Allahu.wav"
#define BLASTER_GRAND_SFX		"leadermode/sabotage_event_01.wav"
#define BLASTER_REVOKE_SFX		"leadermode/drum_02.wav"

new bool:g_rgbBlasterShooting[33];
new g_smodelindexfireball[2], g_idSmokeSprite[4], g_idGibsModels[5];
new cvar_blasterDuration, cvar_blasterCooldown, cvar_explosionDamage, cvar_explosionRange, cvar_exploBulletDmg, cvar_exploBulletRad;

public Blaster_Initialize()
{
	cvar_blasterDuration	= register_cvar("lm_blaster_duration",	"10.0");
	cvar_blasterCooldown	= register_cvar("lm_blaster_cooldown",	"30.0");
	cvar_explosionDamage	= register_cvar("lm_blaster_explosion_damage", "150.0");
	cvar_explosionRange		= register_cvar("lm_blaster_explosion_range", "120.0");
	cvar_exploBulletRad		= register_cvar("lm_blaster_breaching_bullets_rad", "40.0");
	cvar_exploBulletDmg		= register_cvar("lm_blaster_breaching_bullets_dmg", "8.0");

	g_rgSkillDuration[Role_Blaster] = cvar_blasterDuration;
	g_rgSkillCooldown[Role_Blaster] = cvar_blasterCooldown;
}

public Blaster_Precache()
{
	engfunc(EngFunc_PrecacheSound, BLASTER_EXPLODE_SFX);
	g_smodelindexfireball[0] = engfunc(EngFunc_PrecacheModel, "sprites/eexplo.spr");
	g_smodelindexfireball[1] = engfunc(EngFunc_PrecacheModel, "sprites/fexplo.spr");
	
	g_idSmokeSprite[0] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke1.spr");
	g_idSmokeSprite[1] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke2.spr");
	g_idSmokeSprite[2] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke3.spr");
	g_idSmokeSprite[3] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke4.spr");
	
	precache_sound(BLASTER_GRAND_SFX);
	precache_sound(BLASTER_REVOKE_SFX);
	
	g_idGibsModels[0] = engfunc(EngFunc_PrecacheModel, "models/gibs.mdl")
	g_idGibsModels[1] = engfunc(EngFunc_PrecacheModel, "models/gibs2.mdl")
	g_idGibsModels[2] = engfunc(EngFunc_PrecacheModel, "models/gibs3.mdl")
	g_idGibsModels[3] = engfunc(EngFunc_PrecacheModel, "models/gibs4.mdl")
	g_idGibsModels[4] = engfunc(EngFunc_PrecacheModel, "models/gibs5.mdl")
}

public bool:Blaster_ExecuteSkill(pPlayer)
{
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_HEGRENADE]);
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_FLASHBANG]);
	fm_give_item(pPlayer, g_rgszWeaponEntity[CSW_SMOKEGRENADE]);
	
	engclient_cmd(pPlayer, g_rgszWeaponEntity[CSW_HEGRENADE]);	// switch to grenade.
	
	new Float:vecOrigin[3];
	pev(pPlayer, pev_origin,vecOrigin);
	
	new iEntity = -1;	// support other characters.
	while ((iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, vecOrigin, 250.0)) > 0)
	{
		if (!is_user_alive2(iEntity))
			continue;
		
		if (iEntity == pPlayer)
			continue;

		switch (g_rgPlayerRole[iEntity])
		{
			case Role_Sharpshooter:
			{
				if (!(pev(iEntity, pev_weapons) & (1<<CSW_HEGRENADE)) )
					fm_give_item(iEntity, g_rgszWeaponEntity[CSW_HEGRENADE]);
			}
			
			case Role_Medic:
			{
				if (!(pev(iEntity, pev_weapons) & (1<<CSW_SMOKEGRENADE)) )
					fm_give_item(iEntity, g_rgszWeaponEntity[CSW_SMOKEGRENADE]);
			}
			
			default: { }
		}
	}
	
	set_task(get_pcvar_float(cvar_blasterDuration), "Blaster_RevokeSkill", BLASTER_TASK + pPlayer);
	client_cmd(pPlayer, "spk %s", BLASTER_GRAND_SFX);
	return true;
}

public Blaster_RevokeSkill(iTaskId)
{
	new iPlayer = iTaskId - BLASTER_TASK;
	if (!is_user_connected(iPlayer))
		return;

	if (g_rgPlayerRole[iPlayer] != Role_Blaster)
		return;

	g_rgbUsingSkill[iPlayer] = false;
	g_rgflSkillCooldown[iPlayer] = get_gametime() + get_pcvar_float(cvar_blasterCooldown);
	
	print_chat_color(iPlayer, REDCHAT, "技能已结束！");
	client_cmd(iPlayer, "spk %s", BLASTER_REVOKE_SFX);
}

public Blaster_Explosion(iPlayer)
{
	static Float:origin[3];
	pev(iPlayer, pev_origin, origin);
	new i = -1;
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_explosionRange))) > 0)
	{
		if (!pev_valid(i) || iPlayer == i)
			continue;

		if (pev(i, pev_takedamage) == DAMAGE_NO)
			continue;

		static classname[32];
		pev(i, pev_classname, classname, charsmax(classname));
		if (!strcmp(classname, "func_breakable"))
		{
			ExecuteHamB(Ham_TakeDamage, i, iPlayer, iPlayer, get_pcvar_float(cvar_explosionDamage), DMG_BLAST);
			continue;
		}

		new Float:origin2[3];
		pev(i, pev_origin, origin2);

		new Float:flDamage = floatclamp(get_pcvar_float(cvar_explosionDamage)*(1.0 - (get_distance_f(origin2, origin) - 21.0) / get_pcvar_float(cvar_explosionRange)), 0.0, get_pcvar_float(cvar_explosionDamage));
		if (flDamage == 0.0)
			continue;

		ExecuteHamB(Ham_TakeDamage, i, iPlayer, iPlayer, flDamage, DMG_BLAST);
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 25.0);
	write_short(g_smodelindexfireball[1]);
	write_byte(clamp(floatround(get_pcvar_float(cvar_explosionRange) / 6.0), 10, 30));
	write_byte(50);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + random_float(30.0, 35.0));
	write_short(g_smodelindexfireball[0]);
	write_byte(clamp(floatround(get_pcvar_float(cvar_explosionRange) / 6.0), 10, 30));
	write_byte(30);
	write_byte(TE_EXPLFLAG_NONE);
	message_end();

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, BLASTER_EXPLODE_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Breacher_BulletsExplosion(iPlayer, tr)
{
	static Float:vecOrigin[3];
	get_tr2(tr, TR_vecEndPos, vecOrigin);
	
	if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		return;
	
	static Float:vecPlaneNormal[3];
	get_tr2(tr, TR_vecPlaneNormal, vecPlaneNormal);
	
	xs_vec_mul_scalar(vecPlaneNormal, 27.0, vecPlaneNormal);
	xs_vec_add(vecOrigin, vecPlaneNormal, vecOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] - 23.0);
	write_short(g_idSmokeSprite[random_num(0, 3)]);
	write_byte(random_num(10, 15));
	write_byte(random_num(100, 110));
	message_end();
	
	get_tr2(tr, TR_vecEndPos, vecOrigin);
	Breacher_Light(vecOrigin);
	
	new i = -1;
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, vecOrigin, get_pcvar_float(cvar_exploBulletRad))) > 0)
	{
		if (pev_valid(i) != 2)
			continue;
		
		if (pev(i, pev_takedamage) == DAMAGE_NO)
			continue;
		
		new Float:vecVictimOrigin[3];
		pev(i, pev_origin, vecVictimOrigin);
		
		new Float:flDamage = floatclamp(get_pcvar_float(cvar_exploBulletDmg) * (1.0 - (get_distance_f(vecVictimOrigin, vecOrigin) - 21.0) / get_pcvar_float(cvar_exploBulletRad)), 0.0, get_pcvar_float(cvar_exploBulletDmg));
		if (flDamage == 0.0)
			continue;
		
		new iInflictor = get_pdata_cbase(iPlayer, m_pActiveItem);
		ExecuteHamB(Ham_TakeDamage, i, pev_valid(iInflictor) == 2 ? iInflictor : iPlayer, iPlayer, flDamage, DMG_BLAST);
		
		if (!is_user_alive(i))
			continue;
		
		UTIL_ScreenShake(i, -3.0, 0.2, 5.0);
	}
}

public Breacher_MakeGibs(Float:vecCentre[3], Float:vecAngles[3])
{
	new Float:vecOrigin[3], Float:vecVelocity[3]
	get_aim_origin_vector2(vecAngles, vecCentre, 50.0, random_float(-15.0, 15.0), random_float(-15.0, 15.0), vecOrigin)
	
	new Float:flSpeed = floatclamp(get_pcvar_float(cvar_exploBulletDmg) * 3.0 * 5.0, 100.0, 230.0);
	flSpeed = random_float(flSpeed / 2.0, flSpeed);
	
	xs_vec_sub(vecOrigin, vecCentre, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecCentre[0]);
	engfunc(EngFunc_WriteCoord, vecCentre[1]);
	engfunc(EngFunc_WriteCoord, vecCentre[2]);
	engfunc(EngFunc_WriteCoord, 0.1);
	engfunc(EngFunc_WriteCoord, 0.1);
	engfunc(EngFunc_WriteCoord, 0.1);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(0);
	write_short(g_idGibsModels[random_num(0, 4)]);
	write_byte(1);
	write_byte(0);
	write_byte(0);
	message_end();
}

public Breacher_Light(const Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(18 / 2);	// radius
	write_byte(255);	// R
	write_byte(150);	// G
	write_byte(15);		// B
	write_byte(8);		// life
	write_byte(60);		// decay
	message_end();
}

new Float:g_rgflBreacherBotThink[33], Float:g_rgflBreacherBotNextGR[33];

public Breacher_BotThink(pPlayer)
{
	// use his skill when fighting against a player.
	
	if (!is_user_bot(pPlayer) || g_rgflBreacherBotThink[pPlayer] > get_gametime() || !g_bRoundStarted || !is_user_alive(pPlayer))
		return;
	
	if (!g_rgbAllowSkill[pPlayer])
	{
		if (g_rgbUsingSkill[pPlayer] && g_rgflBreacherBotNextGR[pPlayer] <= get_gametime())
		{
			new Float:vecOrigin[3], Float:vecVictimOrigin[3];
			pev(pPlayer, pev_origin, vecOrigin);
			pev(pPlayer, pev_view_ofs, vecVictimOrigin);
			xs_vec_add(vecOrigin, vecVictimOrigin, vecOrigin);
			
			for (new i = 1; i <= global_get(glb_maxClients); i++)
			{
				if (!is_user_alive2(i))
					continue;
				
				if (fm_is_user_same_team(i, pPlayer))
					continue;
				
				pev(i, pev_origin, vecVictimOrigin);
				if (!UTIL_PointVisible(vecOrigin, vecVictimOrigin, IGNORE_MONSTERS))
					continue;
				
				new Float:vecDir[3], Float:vecVAngle[3];
				vecVictimOrigin[2] += 36.0;	// consider the arc.
				xs_vec_sub(vecVictimOrigin, vecOrigin, vecDir);
				engfunc(EngFunc_VecToAngles, vecDir, vecVAngle);
				vecVAngle[0] *= -1.0;
				set_pev(pPlayer, pev_angles, vecVAngle);
				set_pev(pPlayer, pev_v_angle, vecVAngle);
				set_pev(pPlayer, pev_fixangle, 1);
				
				Bot_ForceGrenadeThrow(pPlayer, CSW_HEGRENADE);
				break;
			}
			
			g_rgflBreacherBotNextGR[pPlayer] = get_gametime() + 0.8;
		}
		
		return;
	}
	
	g_rgflBreacherBotThink[pPlayer] = get_gametime() + 0.2;
	
	get_aiming_trace(pPlayer);
	
	new iEntity = get_tr2(0, TR_pHit);
	if (is_user_alive2(iEntity) && !fm_is_user_same_team(pPlayer, iEntity))
	{
		Blaster_ExecuteSkill(pPlayer);
		g_rgbUsingSkill[pPlayer] = true;
		g_rgbAllowSkill[pPlayer] = false;
	}
}

stock get_aim_origin_vector2(Float:vAngle[3], Float:vOrigin[3], Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
