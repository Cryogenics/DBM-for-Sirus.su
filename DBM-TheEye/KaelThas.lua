local mod	= DBM:NewMod("KaelThas", "DBM-TheEye")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 163 $"):sub(12, -3))

mod:SetCreatureID(19622)
mod:RegisterCombat("yell", L.YellPhase1)
mod:SetUsedIcons(6, 7, 8)
mod:AddBoolOption("RemoveWeaponOnMindControl", true)

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"UNIT_TARGET",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_SUCCESS"
)

local warnPhase             = mod:NewAnnounce("WarnPhase", 1)
local warnNextAdd           = mod:NewAnnounce("WarnNextAdd", 2)
local warnTalaTarget        = mod:NewAnnounce("WarnTalaTarget", 4)
local warnConflagrateSoon   = mod:NewSoonAnnounce(37018, 2)
local warnConflagrate       = mod:NewTargetAnnounce(37018, 4)
local warnBombSoon          = mod:NewSoonAnnounce(37036, 2)
local warnBarrierSoon       = mod:NewSoonAnnounce(36815, 2)
local warnPhoenixSoon       = mod:NewSoonAnnounce(36723, 2)
local warnMCSoon            = mod:NewSoonAnnounce(36797, 2)
local warnMC                = mod:NewTargetAnnounce(36797, 3)
local warnGravitySoon       = mod:NewSoonAnnounce(35941, 2)

local specWarnTalaTarget    = mod:NewSpecialWarning("SpecWarnTalaTarget", nil, nil, nil, 1, 2)
local specWarnFlameStrike   = mod:NewSpecialWarningMove(36731, nil, nil, nil, 1, 2)

local timerNextAdd          = mod:NewTimer(30, "TimerNextAdd", "Interface\\Icons\\Spell_Nature_WispSplode", nil, nil, 2)
local timerPhase3           = mod:NewTimer(123, "TimerPhase3", "Interface\\Icons\\Spell_Shadow_AnimateDead", nil, nil, 2)
local timerPhase4           = mod:NewTimer(180, "TimerPhase4", 34753, nil, nil, 2)
local timerTalaTarget       = mod:NewTimer(8.5, "TimerTalaTarget", "Interface\\Icons\\Spell_Fire_BurningSpeed")
local timerRoarCD           = mod:NewCDTimer(31, 40636, nil, nil, nil, 3)
local timerConflagrateCD    = mod:NewCDTimer(20, 37018, nil, nil, nil, 3)
local timerBombCD           = mod:NewCDTimer(25, 37036, nil, nil, nil, 3)
local timerFlameStrike      = mod:NewCDTimer(35, 36731, nil, nil, nil, 3)

local timerBarrierCD        = mod:NewCDTimer(70, 36815, nil, nil, nil, 3)
local timerPhoenixCD        = mod:NewCDTimer(60, 36723, nil, nil, nil, 1, nil, DBM_CORE_DAMAGE_ICON)
local timerMCCD             = mod:NewCDTimer(70, 36797, nil, nil, nil, 3)

local timerGravity          = mod:NewTimer(32.5, "TimerGravity", "Interface\\Icons\\Spell_Magic_FeatherFall", nil, nil, 4, nil, DBM_CORE_DEADLY_ICON, nil, 2, 4)
local timerGravityCD        = mod:NewCDTimer(90, 35941, nil, nil, nil, 4, nil, DBM_CORE_DEADLY_ICON, nil, 2, 4)

--------------------------хм------------------------

local warnFurious		= mod:NewStackAnnounce(308732, 2, nil, "Tank|Healer") -- яростный удар
local warnJustice		= mod:NewStackAnnounce(308741, 2, nil, "Tank|Healer") -- правосудие тьмы
local warnShadow        = mod:NewSoonAnnounce(308742, 2) -- освященеи тенью (лужа)
--local warnBombhm        = mod:NewSoonAnnounce(308, 2)--бомба

local timerFuriousCD     = mod:NewCDTimer(7, 308732, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerFurious		= mod:NewTargetTimer(30, 308732, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerJusticeCD    = mod:NewCDTimer(9, 308741, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerJustice		= mod:NewTargetTimer(30, 308741, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerShadowCD		= mod:NewCDTimer(17, 308742, nil, nil, nil, 4)
--local timerBurningCD    = mod:NewCDTimer(8, 308741, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON)
--local timerBurning		= mod:NewTargetTimer(30, 308741, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON)



----------------------------------------------------



mod:AddBoolOption("SetIconOnMC", true)

mod.vb.phase = 0

local dominateMindTargets = {}
local dominateMindIcon = 8
local mincControl = {}
local axe = true

function mod:AxeIcon()
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == L.Axe then
			axe = false
			SetRaidTarget("raid"..i.."target", 8)
			break
		end
	end
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 19622, "Kael'thas Sunstrider")
	self.vb.phase = 1
	dominateMindIcon = 8
	axe = true
	warnPhase:Show(L.WarnPhase1)
	timerNextAdd:Start(L.NamesAdds["Thaladred"])
	table.wipe(dominateMindTargets)
	table.wipe(mincControl)
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 19622, "Kael'thas Sunstrider", wipe)
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg:match(L.TalaTarget) then
		local target = msg:sub(29,-3) or "Unknown"
		warnTalaTarget:Show(target)
		timerTalaTarget:Start(target)
		if target == UnitName("player") then
			specWarnTalaTarget:Show()
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellSang then
		timerTalaTarget:Cancel()
		warnNextAdd:Show(L.NamesAdds["Lord Sanguinar"])
		timerNextAdd:Start(12.5, L.NamesAdds["Lord Sanguinar"])
		timerRoarCD:Start(33)
	elseif msg == L.YellCaper then
		timerRoarCD:Cancel()
		warnNextAdd:Show(L.NamesAdds["Capernian"])
		timerNextAdd:Start(7, L.NamesAdds["Capernian"])
		DBM.RangeCheck:Show(10)
	elseif msg == L.YellTelon then
		DBM.RangeCheck:Hide()
		warnConflagrateSoon:Cancel()
		timerConflagrateCD:Cancel()
		warnNextAdd:Show(L.NamesAdds["Telonicus"])
		timerNextAdd:Start(8.4, L.NamesAdds["Telonicus"])
		warnBombSoon:Schedule(13)
		timerBombCD:Start(18)
	elseif msg == L.YellPhase2 then
		self.vb.phase = 2
		warnBombSoon:Cancel()
		timerBombCD:Cancel()
		warnPhase:Show(L.WarnPhase2)
		timerPhase3:Start()
	elseif msg == L.YellPhase3  then
		self.vb.phase = 3
		warnPhase:Show(L.WarnPhase3)
		timerPhase4:Start()
		timerRoarCD:Start()
		warnBombSoon:Schedule(10)
		timerBombCD:Start(15)
		DBM.RangeCheck:Show(10)
	elseif msg == L.YellPhase4  then
		self.vb.phase = 4
		warnPhase:Show(L.WarnPhase4)
		timerPhase4:Cancel()
		DBM.RangeCheck:Hide()
		timerRoarCD:Cancel()
		warnBombSoon:Cancel()
		timerBombCD:Cancel()
		warnConflagrateSoon:Cancel()
		timerConflagrateCD:Cancel()
		timerMCCD:Start(40)
		timerBarrierCD:Start(60)
		timerPhoenixCD:Start(50)
		warnBarrierSoon:Schedule(55)
		warnPhoenixSoon:Schedule(45)
		warnMCSoon:Schedule(35)
	elseif msg == L.YellPhase5  then
		self.vb.phase = 5
		warnPhase:Show(L.WarnPhase5)
		timerMCCD:Cancel()
		warnMCSoon:Cancel()
		timerGravityCD:Start()
		warnGravitySoon:Schedule(85)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(36797) then
		if args:IsPlayer() and self.Options.RemoveWeaponOnMindControl then
		   if self:IsWeaponDependent("player") then
				PickupInventoryItem(16)
				PutItemInBackpack()
				PickupInventoryItem(17)
				PutItemInBackpack()
			elseif select(2, UnitClass("player")) == "HUNTER" then
				PickupInventoryItem(18)
				PutItemInBackpack()
			end
		end
		dominateMindTargets[#dominateMindTargets + 1] = args.destName
		if self.Options.SetIconOnDominateMind then
			self:SetIcon(args.destName, dominateMindIcon, 12)
			dominateMindIcon = dominateMindIcon - 1
		end
--		self:Unschedule(showDominateMindWarning)
--		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("normal25") or (mod:IsDifficulty("heroic25") and #dominateMindTargets >= 3) then
--			showDominateMindWarning()
--		else
--			self:Schedule(0.9, showDominateMindWarning)
--		end
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(40636) then
		timerRoarCD:Start()
	elseif args:IsSpellID(37036) then
		warnBombSoon:Schedule(20)
		timerBombCD:Start()
	elseif args:IsSpellID(35941) then
		timerGravity:Start()
		timerGravityCD:Start()
		warnGravitySoon:Schedule(85)
    elseif args:IsSpellID(308742) then --освящение тенью
	    timerShadowCD:Start()	
		warnShadow:Schedule(0)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(37018) then
		warnConflagrate:Show(args.destName)
		warnConflagrateSoon:Cancel()
		warnConflagrateSoon:Schedule(16)
		timerConflagrateCD:Start()
	elseif args:IsSpellID(36723) then
		timerPhoenixCD:Start()
		warnPhoenixSoon:Schedule(55)
	elseif args:IsSpellID(36815) then
		timerBarrierCD:Start()
		warnBarrierSoon:Schedule(65)
	elseif args:IsSpellID(36731) then
		timerFlameStrike:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(36797) then
		timerMCCD:Start()
		warnMCSoon:Schedule(65)
		mincControl[#mincControl + 1] = args.destName
		if #mincControl >= 3 then
			warnMC:Show(table.concat(mincControl, "<, >"))
			if self.Options.SetIconOnMC then
				table.sort(mincControl, function(v1,v2) return DBM:GetRaidSubgroup(v1) < DBM:GetRaidSubgroup(v2) end)
				local MCIcons = 8
				for i, v in ipairs(mincControl) do
					self:SetIcon(v, MCIcons)
					MCIcons = MCIcons - 1
				end
			end
			table.wipe(mincControl)
		end
	elseif args:IsSpellID(308732) then --хм яростный удар
        warnFurious:Show(args.destName, args.amount or 1)	
		timerFurious:Start(args.destName)
		timerFuriousCD:Start()	
	elseif args:IsSpellID(308741) then --хм Правосудие тенью
		timerJusticeCD:Start()	
        warnJustice:Show(args.destName, args.amount or 1)	
		timerJustice:Start(args.destName)	
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args) ---??
	if args:IsSpellID(308732) then --хм яростный удар
        warnFurious:Show(args.destName, args.amount or 1)	
		timerFurious:Start(args.destName)
		timerFuriousCD:Start()	
	elseif args:IsSpellID(308741) then --хм Правосудие тенью
		timerJusticeCD:Start()	
        warnJustice:Show(args.destName, args.amount or 1)	
		timerJustice:Start(args.destName)	
	end
end



function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(36797) then
		self:SetIcon(args.destName, 0)
	end
end

function mod:UNIT_TARGET()
	if axe then
		self:AxeIcon()
	end
end
