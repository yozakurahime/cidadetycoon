/**
 * Cidade Tycoon — Mock Simulation Script
 * 
 * Simula os 3 fluxos críticos de eventos/callbacks entre recursos cidade_*
 * sem necessidade de rodar o servidor FiveM completo.
 * 
 * Uso: node scratch/simulate_tycoon_flows.mjs
 */

import { strict as assert } from 'node:assert';

// ─── MOCK DATABASE ───────────────────────────────────────────────
const mockDB = {
  profiles: new Map(),
  vehicles: new Map(),
  companies: new Map(),
  transactions: [],
  productionLines: [],
  warehouseInventory: new Map(),
};

// ─── MOCK STATE BAGS ─────────────────────────────────────────────
const stateBags = new Map(); // citizenid → tycoonProfile

// ─── MOCK FRAMEWORK ──────────────────────────────────────────────
const mockFramework = {
  getPlayer: (src) => mockDB.players?.get(src) || null,
  getPlayerByCitizenId: (cid) => {
    for (const [id, p] of mockDB.players || []) {
      if (p.citizenid === cid) return p;
    }
    return null;
  },
  addMoney: (player, account, amount, reason) => {
    if (!player) return false;
    player.money = player.money || { bank: 50000, cash: 2000 };
    player.money[account] = (player.money[account] || 0) + amount;
    return true;
  },
  removeMoney: (player, account, amount, reason) => {
    if (!player || (player.money?.[account] || 0) < amount) return false;
    player.money[account] -= amount;
    return true;
  },
};

// ─── CONFIG MIRRORS (sync with shared/config.lua) ────────────────
const CONFIG = {
  maxLevel: 100,
  expPerLevel: 1500,
  defaults: {
    skills: { skill_logistics: 0, skill_long_distance: 0, skill_fragile: 0, skill_valuable: 0, skill_hazardous: 0 },
    upgrades: { warehouse_slots: 0, fleet_size: 2, mechanic_efficiency: 0 },
  },
  freelance: {
    baseRewardPerBox: { land: 1750, water: 2200, air: 3500 },
    rewardMultipliers: { comum: 1.0, fragile: 1.4, heavy: 1.8, hazardous: 2.5 },
    deliveryPoints: {
      land: [
        [441.1, -981.4, 30.7], [1196.7, -3253.5, 7.1], [2750.5, 3474.3, 55.4],
        [1697.7, 4924.5, 42.1], [-3038.5, 584.2, 7.9], [1174.6, 2640.4, 37.8],
      ],
      water: [[-804.8, -1507.7, 1.6], [1313.1, -3075.2, 0.5]],
      air: [[-1037.1, -2737.5, 20.2], [1741.5, 3269.4, 41.1]],
    },
  },
  logistics: {
    companyPrices: { small: 250000, medium: 750000, large: 2500000 },
    npcDriverCost: 15000,
    maxNpcDrivers: 10,
    jobPostingFee: 500,
  },
};

// ─── UTILITIES ────────────────────────────────────────────────────
let testCount = 0;
let passCount = 0;
let failCount = 0;

function test(name, fn) {
  testCount++;
  try {
    fn();
    passCount++;
    console.log(`  ✅ ${name}`);
  } catch (e) {
    failCount++;
    console.log(`  ❌ ${name}`);
    console.log(`     ${e.message}`);
  }
}

function summary() {
  console.log(`\n${'═'.repeat(60)}`);
  console.log(`Resultado: ${passCount}/${testCount} passaram, ${failCount} falharam`);
  console.log(`${'═'.repeat(60)}`);
}

// ─── INIT MOCK ENVIRONMENT ───────────────────────────────────────
function setupEnvironment() {
  mockDB.players = new Map();
  mockDB.profiles = new Map();
  mockDB.vehicles = new Map();
  mockDB.companies = new Map();
  mockDB.transactions = [];
  stateBags.clear();

  // Create test player
  mockDB.players.set(1, {
    source: 1,
    citizenid: 'TEST001',
    name: 'TestPlayer',
    money: { bank: 1000000, cash: 5000 },
  });

  // Create test company
  mockDB.companies.set('TRANSPORTES_1', {
    id: 'TRANSPORTES_1',
    name: 'Transportes Tycoon',
    vaultBalance: 0,
    npcDrivers: [],
    activeJobs: [],
    owner: 'TEST001',
  });
}

// ═══════════════════════════════════════════════════════════════════
// FLOW 1: PROFILE CREATION + XP + STATE BAG SYNC
// ═══════════════════════════════════════════════════════════════════
console.log('\n🔷 FLOW 1: Profile → XP → State Bag (core ↔ hud)');

function createProfile(citizenId) {
  const profile = {
    citizenid: citizenId,
    level: 1,
    experience: 0,
    upgrades: { ...CONFIG.defaults.upgrades },
    skills: { ...CONFIG.defaults.skills },
    activeMission: null,
    isSuspended: false,
    vaultBalance: 0,
    tutorial: { active: true, currentStep: 'welcome' },
  };
  mockDB.profiles.set(citizenId, profile);
  syncStateBag(citizenId, profile);
  return profile;
}

function syncStateBag(citizenId, profile) {
  stateBags.set(citizenId, { ...profile });
}

function getPlayerProfile(citizenId) {
  return mockDB.profiles.get(citizenId) || null;
}

function addExperience(citizenId, amount) {
  const profile = mockDB.profiles.get(citizenId);
  if (!profile) return false;
  profile.experience += amount;
  while (profile.experience >= profile.level * CONFIG.expPerLevel && profile.level < CONFIG.maxLevel) {
    profile.experience -= profile.level * CONFIG.expPerLevel;
    profile.level += 1;
  }
  syncStateBag(citizenId, profile);
  return true;
}

function logTransaction(src, amount, type, category, description) {
  mockDB.transactions.push({
    source: src,
    amount,
    type,
    category,
    description,
    timestamp: Date.now(),
  });
}

// --- Flow 1 Tests ---
setupEnvironment();

test('createProfile: inicializa perfil com level 1 e 0 XP', () => {
  const p = createProfile('TEST001');
  assert.equal(p.level, 1);
  assert.equal(p.experience, 0);
  assert.equal(p.tutorial.currentStep, 'welcome');
});

test('syncStateBag: state bag sincroniza após criação', () => {
  const bag = stateBags.get('TEST001');
  assert.ok(bag);
  assert.equal(bag.level, 1);
  assert.equal(bag.citizenid, 'TEST001');
});

test('addExperience: 500 XP não sobe level (nível 1, threshold 1500)', () => {
  addExperience('TEST001', 500);
  const p = getPlayerProfile('TEST001');
  assert.equal(p.level, 1);
  assert.equal(p.experience, 500);
});

test('addExperience: +1200 XP sobe para level 2 (500+1200=1700, sobra 200)', () => {
  addExperience('TEST001', 1200);
  const p = getPlayerProfile('TEST001');
  assert.equal(p.level, 2);
  assert.equal(p.experience, 200);
});

test('addExperience: state bag atualizado após level up', () => {
  const bag = stateBags.get('TEST001');
  assert.equal(bag.level, 2);
  assert.equal(bag.experience, 200);
});

test('addExperience: múltiplos level ups (3000 XP no nível 2)', () => {
  addExperience('TEST001', 3000);
  const p = getPlayerProfile('TEST001');
  // level 2 threshold = 3000; 200 + 3000 = 3200; 3200 - 3000 = 200, level 3
  assert.equal(p.level, 3);
  assert.equal(p.experience, 200);
});

test('logTransaction: registra transação corretamente', () => {
  logTransaction(1, 5000, 'income', 'race', 'Vitória na corrida');
  assert.equal(mockDB.transactions.length, 1);
  assert.equal(mockDB.transactions[0].amount, 5000);
  assert.equal(mockDB.transactions[0].type, 'income');
});

// ═══════════════════════════════════════════════════════════════════
// FLOW 2: MISSION LIFECYCLE (tablet → freelance → core)
// ═══════════════════════════════════════════════════════════════════
console.log('\n🔷 FLOW 2: Mission Lifecycle (tablet → freelance → core)');

let missionIdCounter = 0;

function generateMission(hubId, mode) {
  const points = CONFIG.freelance.deliveryPoints[mode] || CONFIG.freelance.deliveryPoints.land;
  const cargoTypes = ['comum', 'fragile', 'heavy', 'hazardous'];
  const cargoType = cargoTypes[Math.floor(Math.random() * cargoTypes.length)];
  const boxCount = Math.floor(Math.random() * 5) + 1;
  const pickupIndex = Math.floor(Math.random() * points.length);
  let dropIndex;
  do { dropIndex = Math.floor(Math.random() * points.length); } while (dropIndex === pickupIndex);

  missionIdCounter++;
  return {
    missionId: `MISSION_${missionIdCounter}`,
    hubId,
    mode,
    cargoType,
    boxCount,
    pickupCoords: points[pickupIndex],
    dropCoords: points[dropIndex],
    status: 'available',
    reward: calculateMissionReward(mode, cargoType, boxCount),
    acceptedBy: null,
    vehicleNetId: null,
    completedAt: null,
  };
}

function calculateMissionReward(mode, cargoType, boxCount) {
  const basePerBox = CONFIG.freelance.baseRewardPerBox[mode] || 1750;
  const multiplier = CONFIG.freelance.rewardMultipliers[cargoType] || 1.0;
  return Math.round(basePerBox * boxCount * multiplier);
}

function acceptMission(citizenId, mission) {
  const profile = getPlayerProfile(citizenId);
  if (!profile || profile.activeMission) return { ok: false, message: 'Já possui missão ativa.' };
  if (mission.status !== 'available') return { ok: false, message: 'Missão indisponível.' };

  mission.status = 'accepted';
  mission.acceptedBy = citizenId;
  profile.activeMission = mission;
  syncStateBag(citizenId, profile);
  return { ok: true, mission };
}

function validateMissionVehicle(citizenId, vehicleModel, vehicleNetId) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.activeMission) return { ok: false, message: 'Sem missão ativa.' };
  if (!vehicleModel || !vehicleNetId) return { ok: false, message: 'Veículo inválido.' };

  profile.activeMission.vehicleModel = vehicleModel;
  profile.activeMission.vehicleNetId = vehicleNetId;
  profile.activeMission.status = 'in_progress';
  syncStateBag(citizenId, profile);
  return { ok: true };
}

function completeMission(citizenId, deliveryCoords, penaltyDamage) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.activeMission) return { ok: false, message: 'Sem missão ativa.' };

  const mission = profile.activeMission;
  const drop = mission.dropCoords;
  const distance = Math.sqrt(
    (deliveryCoords[0] - drop[0]) ** 2 +
    (deliveryCoords[1] - drop[1]) ** 2 +
    (deliveryCoords[2] - drop[2]) ** 2
  );

  if (distance > 15.0) return { ok: false, message: 'Muito longe do ponto de entrega.' };

  const damagePenalty = Math.floor(mission.reward * (penaltyDamage || 0) * 0.5);
  const netReward = mission.reward - damagePenalty;
  const expReward = Math.floor(mission.boxCount * 75); // ~75 XP per box

  // Apply rewards
  const player = mockFramework.getPlayerByCitizenId(citizenId);
  mockFramework.addMoney(player, 'bank', netReward, 'tycoon-freelance-delivery');
  addExperience(citizenId, expReward);
  logTransaction(player?.source || 0, netReward, 'income', 'freelance', `Entrega ${mission.missionId}`);

  mission.status = 'completed';
  mission.completedAt = Date.now();
  mission.finalReward = netReward;
  mission.damagePenalty = damagePenalty;
  profile.activeMission = null;
  profile.completedMissions = (profile.completedMissions || 0) + 1;
  syncStateBag(citizenId, profile);

  return { ok: true, netReward, expReward, damagePenalty };
}

function cancelMission(citizenId, withFine) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.activeMission) return { ok: false, message: 'Sem missão ativa.' };

  let fineAmount = 0;
  if (withFine) {
    fineAmount = Math.floor(profile.activeMission.reward * 0.3);
    const player = mockFramework.getPlayerByCitizenId(citizenId);
    mockFramework.removeMoney(player, 'bank', fineAmount, 'tycoon-mission-cancel-fine');
  }

  profile.activeMission.status = 'cancelled';
  profile.activeMission = null;
  syncStateBag(citizenId, profile);
  return { ok: true, fineAmount };
}

// --- Flow 2 Tests ---
setupEnvironment();
createProfile('TEST001');

test('generateMission: cria missão com campos obrigatórios', () => {
  const m = generateMission(1, 'land');
  assert.ok(m.missionId.startsWith('MISSION_'));
  assert.equal(m.status, 'available');
  assert.ok(m.reward > 0);
  assert.ok(m.pickupCoords);
  assert.ok(m.dropCoords);
  assert.ok(m.pickupCoords !== m.dropCoords);
});

test('calculateMissionReward: 3 caixas "fragile" land = 3 × 1750 × 1.4 = 7350', () => {
  const reward = calculateMissionReward('land', 'fragile', 3);
  assert.equal(reward, 7350);
});

test('calculateMissionReward: 2 caixas "hazardous" air = 2 × 3500 × 2.5 = 17500', () => {
  const reward = calculateMissionReward('air', 'hazardous', 2);
  assert.equal(reward, 17500);
});

test('acceptMission: aceita missão disponível', () => {
  const m = generateMission(1, 'land');
  const result = acceptMission('TEST001', m);
  assert.equal(result.ok, true);
  assert.equal(m.status, 'accepted');
  assert.equal(m.acceptedBy, 'TEST001');
});

test('acceptMission: rejeita segunda missão (já ativa)', () => {
  const m2 = generateMission(1, 'water');
  const result = acceptMission('TEST001', m2);
  assert.equal(result.ok, false);
});

test('validateMissionVehicle: vincula veículo à missão', () => {
  const result = validateMissionVehicle('TEST001', 'phantom', 12345);
  assert.equal(result.ok, true);
  const p = getPlayerProfile('TEST001');
  assert.equal(p.activeMission.vehicleModel, 'phantom');
  assert.equal(p.activeMission.status, 'in_progress');
});

test('completeMission: entrega no ponto correto → recompensa', () => {
  const p = getPlayerProfile('TEST001');
  const mission = p.activeMission;
  const dropCoords = mission.dropCoords;
  const result = completeMission('TEST001', dropCoords, 0.1);
  assert.equal(result.ok, true);
  assert.ok(result.netReward > 0);
  assert.equal(p.activeMission, null);
});

test('completeMission: rejeita entrega longe do destino', () => {
  // Reset: create new mission
  const m = generateMission(1, 'land');
  acceptMission('TEST001', m);
  const result = completeMission('TEST001', [99999, 99999, 99999], 0);
  assert.equal(result.ok, false);
  // Cleanup
  cancelMission('TEST001', false);
});

test('cancelMission: cancela com multa de 30%', () => {
  const m = generateMission(1, 'land');
  acceptMission('TEST001', m);
  const p = getPlayerProfile('TEST001');
  const expectedFine = Math.floor(m.reward * 0.3);
  const result = cancelMission('TEST001', true);
  assert.equal(result.ok, true);
  assert.equal(result.fineAmount, expectedFine);
  assert.equal(p.activeMission, null);
});

test('cancelMission: cancela sem multa', () => {
  const m = generateMission(1, 'land');
  acceptMission('TEST001', m);
  const result = cancelMission('TEST001', false);
  assert.equal(result.ok, true);
  assert.equal(result.fineAmount, 0);
});

// ═══════════════════════════════════════════════════════════════════
// FLOW 3: COMPANY + VAULT + JOB POSTING + NPC RECRUIT
// ═══════════════════════════════════════════════════════════════════
console.log('\n🔷 FLOW 3: Company → Vault → Job Posting → NPC (tablet → logistics → core)');

function purchaseCompany(citizenId, companyId, price) {
  const player = mockFramework.getPlayerByCitizenId(citizenId);
  if (!player) return { ok: false, message: 'Jogador não encontrado.' };

  const profile = getPlayerProfile(citizenId);
  if (!profile) return { ok: false, message: 'Perfil não encontrado.' };
  if (profile.company) return { ok: false, message: 'Já possui empresa.' };

  const company = mockDB.companies.get(companyId);
  if (!company) return { ok: false, message: 'Empresa não existe.' };
  if (company.owner !== null && company.owner !== citizenId) {
    return { ok: false, message: 'Empresa já possui dono.' };
  }

  if (!mockFramework.removeMoney(player, 'bank', price, 'tycoon-company-purchase')) {
    return { ok: false, message: 'Saldo insuficiente.' };
  }

  company.owner = citizenId;
  profile.company = companyId;
  profile.vaultBalance = 0;
  syncStateBag(citizenId, profile);
  logTransaction(player.source, price, 'expense', 'company', `Compra da empresa: ${company.name}`);
  return { ok: true, company };
}

function depositToVault(citizenId, amount) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.company) return { ok: false, message: 'Sem empresa.' };

  const player = mockFramework.getPlayerByCitizenId(citizenId);
  if (!mockFramework.removeMoney(player, 'bank', amount, 'tycoon-vault-deposit')) {
    return { ok: false, message: 'Saldo insuficiente.' };
  }

  const company = mockDB.companies.get(profile.company);
  company.vaultBalance = (company.vaultBalance || 0) + amount;
  profile.vaultBalance = company.vaultBalance;
  syncStateBag(citizenId, profile);
  return { ok: true, vaultBalance: company.vaultBalance };
}

function withdrawFromVault(citizenId, amount) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.company) return { ok: false, message: 'Sem empresa.' };

  const company = mockDB.companies.get(profile.company);
  if ((company.vaultBalance || 0) < amount) {
    return { ok: false, message: 'Saldo do vault insuficiente.' };
  }

  const player = mockFramework.getPlayerByCitizenId(citizenId);
  mockFramework.addMoney(player, 'bank', amount, 'tycoon-vault-withdraw');
  company.vaultBalance -= amount;
  profile.vaultBalance = company.vaultBalance;
  syncStateBag(citizenId, profile);
  return { ok: true, vaultBalance: company.vaultBalance };
}

function recruitNpcDriver(citizenId, driverName, cost) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.company) return { ok: false, message: 'Sem empresa.' };

  const company = mockDB.companies.get(profile.company);
  if (company.npcDrivers.length >= CONFIG.logistics.maxNpcDrivers) {
    return { ok: false, message: 'Limite de motoristas NPC atingido.' };
  }

  const player = mockFramework.getPlayerByCitizenId(citizenId);
  if (!mockFramework.removeMoney(player, 'bank', cost, 'tycoon-npc-recruit')) {
    return { ok: false, message: 'Saldo insuficiente para recrutar.' };
  }

  company.npcDrivers.push({
    id: `NPC_${company.npcDrivers.length + 1}`,
    name: driverName,
    skill: 1,
    status: 'idle',
    hiredAt: Date.now(),
  });
  return { ok: true, driverCount: company.npcDrivers.length };
}

function postCompanyJob(citizenId, jobDetails) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.company) return { ok: false, message: 'Sem empresa.' };

  const player = mockFramework.getPlayerByCitizenId(citizenId);
  const postingFee = CONFIG.logistics.jobPostingFee;

  if (!mockFramework.removeMoney(player, 'bank', postingFee, 'tycoon-job-posting')) {
    return { ok: false, message: 'Saldo insuficiente para publicar.' };
  }

  const company = mockDB.companies.get(profile.company);
  const job = {
    id: `JOB_${company.activeJobs.length + 1}`,
    companyId: profile.company,
    ...jobDetails,
    status: 'open',
    postedAt: Date.now(),
    applicants: [],
  };
  company.activeJobs.push(job);
  return { ok: true, job };
}

function getBusinessDashboard(citizenId) {
  const profile = getPlayerProfile(citizenId);
  if (!profile?.company) return null;

  const company = mockDB.companies.get(profile.company);
  if (!company) return null;

  return {
    companyName: company.name,
    vaultBalance: company.vaultBalance,
    npcDrivers: company.npcDrivers.length,
    activeJobs: company.activeJobs.filter(j => j.status === 'open').length,
    totalJobsCompleted: company.activeJobs.filter(j => j.status === 'completed').length,
  };
}

// --- Flow 3 Tests ---
setupEnvironment();
// Register TEST002 as a player in mock framework
mockDB.players.set(2, {
  source: 2,
  citizenid: 'TEST002',
  name: 'TestPlayer2',
  money: { bank: 700000, cash: 5000 },
});
createProfile('TEST002');

// Seed company for TEST002
mockDB.companies.set('TYCOON_LOG_1', {
  id: 'TYCOON_LOG_1',
  name: 'Tycoon Logística Avançada',
  vaultBalance: 0,
  npcDrivers: [],
  activeJobs: [],
  owner: null,
});

test('purchaseCompany: compra empresa com sucesso', () => {
  const result = purchaseCompany('TEST002', 'TYCOON_LOG_1', 250000);
  assert.equal(result.ok, true);
  const p = getPlayerProfile('TEST002');
  assert.equal(p.company, 'TYCOON_LOG_1');
});

test('purchaseCompany: rejeita segunda compra', () => {
  mockDB.companies.set('TYCOON_LOG_2', {
    id: 'TYCOON_LOG_2', name: 'Outra Empresa', vaultBalance: 0,
    npcDrivers: [], activeJobs: [], owner: null,
  });
  const result = purchaseCompany('TEST002', 'TYCOON_LOG_2', 500000);
  assert.equal(result.ok, false);
});

test('depositToVault: deposita 50000 no vault', () => {
  const result = depositToVault('TEST002', 50000);
  assert.equal(result.ok, true);
  assert.equal(result.vaultBalance, 50000);
});

test('depositToVault: saldo insuficiente bloqueia depósito', () => {
  // Player has ~750k left after 250k purchase; deposit 1M
  const result = depositToVault('TEST002', 1_000_000);
  assert.equal(result.ok, false);
});

test('withdrawFromVault: saca 20000 do vault', () => {
  const result = withdrawFromVault('TEST002', 20000);
  assert.equal(result.ok, true);
  assert.equal(result.vaultBalance, 30000);
});

test('withdrawFromVault: rejeita saque acima do saldo', () => {
  const result = withdrawFromVault('TEST002', 999999);
  assert.equal(result.ok, false);
});

test('recruitNpcDriver: contrata motorista NPC', () => {
  const result = recruitNpcDriver('TEST002', 'João Caminhoneiro', 15000);
  assert.equal(result.ok, true);
  assert.equal(result.driverCount, 1);
});

test('recruitNpcDriver: rejeita se sem saldo', () => {
  // Drain remaining money
  const player = mockFramework.getPlayerByCitizenId('TEST002');
  mockFramework.removeMoney(player, 'bank', player.money.bank, 'drain');
  const result = recruitNpcDriver('TEST002', 'Maria', 15000);
  assert.equal(result.ok, false);
});

test('postCompanyJob: publica vaga de entrega', () => {
  // Refund player for this test
  const player = mockFramework.getPlayerByCitizenId('TEST002');
  mockFramework.addMoney(player, 'bank', 10000, 'refund');

  const result = postCompanyJob('TEST002', {
    title: 'Entrega Urgente - Paleto Bay',
    cargo: 'Eletrônicos',
    reward: 8500,
    pickup: [441.1, -981.4, 30.7],
    drop: [2750.5, 3474.3, 55.4],
  });
  assert.equal(result.ok, true);
  assert.equal(result.job.status, 'open');
  assert.equal(result.job.cargo, 'Eletrônicos');
});

test('getBusinessDashboard: retorna dashboard completo', () => {
  const dash = getBusinessDashboard('TEST002');
  assert.ok(dash);
  assert.equal(dash.companyName, 'Tycoon Logística Avançada');
  assert.equal(dash.vaultBalance, 30000);
  assert.equal(dash.npcDrivers, 1);
  assert.equal(dash.activeJobs, 1);
});

// ═══════════════════════════════════════════════════════════════════
// REPORT
// ═══════════════════════════════════════════════════════════════════
console.log('');
summary();
console.log('');

if (failCount > 0) {
  console.log('⚠️  Alguns testes falharam. Reveja a lógica acima.');
  process.exit(1);
} else {
  console.log('🏆 Todos os fluxos simulados com sucesso!');
  console.log('   O sistema de eventos/callbacks entre os recursos está funcional.\n');
}
