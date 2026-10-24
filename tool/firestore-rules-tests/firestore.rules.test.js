import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteApp, initializeApp } from 'firebase/app';
import {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  deleteUser,
  initializeAuth,
  inMemoryPersistence,
} from 'firebase/auth';
import {
  collection,
  connectFirestoreEmulator,
  deleteDoc,
  doc,
  getDocs,
  getDoc,
  getFirestore,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = fs.readFileSync(path.resolve(here, '../../firestore.rules'), 'utf8');
const guestId = 'guest-1';
const otherGuestId = 'guest-2';
const hostId = 'host-1';
let env;

function booking(overrides = {}) {
  return {
    id: 'booking-1',
    guestId,
    homestayId: 'stay-1',
    status: 'pending',
    guests: 2,
    checkInEpochMillis: Date.now() + 10 * 24 * 60 * 60 * 1000,
    payments: [],
    ...overrides,
  };
}

function review(overrides = {}) {
  return {
    bookingId: 'booking-1',
    guestId,
    homestayId: 'stay-1',
    rating: 5,
    ...overrides,
  };
}

async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hhl-stay-rules',
    firestore: { rules },
  });
});

after(async () => {
  await env.cleanup();
});

test('catalog is public, while finance and staff records are host-only', async () => {
  const guest = env.authenticatedContext(guestId).firestore();
  const anonymous = env.unauthenticatedContext().firestore();
  const host = env.authenticatedContext(hostId).firestore();
  await seed('homestays/stay-1', { name: 'Stay' });
  await seed('financeEntries/entry-1', { amount: 100 });
  await seed('staffMembers/staff-1', { name: 'Staff' });
  await seed(`users/${hostId}`, {
    uid: hostId,
    email: 'host@example.test',
    role: 'host',
  });

  await assertSucceeds(getDoc(doc(anonymous, 'homestays/stay-1')));
  await assertFails(getDoc(doc(guest, 'financeEntries/entry-1')));
  await assertFails(getDoc(doc(guest, 'staffMembers/staff-1')));
  await assertSucceeds(getDoc(doc(host, 'financeEntries/entry-1')));
  await assertSucceeds(getDoc(doc(host, 'staffMembers/staff-1')));
});

test('users can create only their own guest account and cannot promote their role', async () => {
  const guest = env.authenticatedContext(guestId, {
    email: 'guest@example.test',
  }).firestore();
  const guestRef = doc(guest, `users/${guestId}`);

  await assertSucceeds(setDoc(guestRef, {
    uid: guestId,
    email: 'guest@example.test',
    role: 'guest',
    displayName: 'Guest',
  }));
  await assertSucceeds(updateDoc(guestRef, { displayName: 'Updated' }));
  await assertFails(updateDoc(guestRef, { role: 'host' }));
  await assertFails(setDoc(doc(guest, `users/${otherGuestId}`), {
    uid: otherGuestId,
    email: 'other@example.test',
    role: 'guest',
  }));
});

test('a guest can create and read their pending booking, but another guest cannot read it', async () => {
  const guest = env.authenticatedContext(guestId).firestore();
  const otherGuest = env.authenticatedContext(otherGuestId).firestore();
  const bookingRef = doc(guest, `bookings/${guestId}_booking-1`);

  await assertSucceeds(setDoc(bookingRef, booking()));
  await assertSucceeds(getDoc(bookingRef));
  await assertFails(getDoc(doc(otherGuest, `bookings/${guestId}_booking-1`)));
  await assertFails(setDoc(doc(guest, `bookings/${guestId}_booking-2`), booking({
    id: 'booking-2',
    status: 'confirmed',
  })));
  await assertFails(setDoc(doc(guest, `bookings/${guestId}_booking-3`), booking({
    id: 'booking-3',
    guests: 0,
  })));
});

test('a guest may cancel their own pending booking but cannot edit price or restore it', async () => {
  const guest = env.authenticatedContext(guestId).firestore();
  const bookingRef = doc(guest, `bookings/${guestId}_booking-1`);
  await seed(`bookings/${guestId}_booking-1`, booking());

  await assertSucceeds(updateDoc(bookingRef, { status: 'cancelled' }));
  await assertFails(updateDoc(bookingRef, { status: 'confirmed' }));
  await seed(`bookings/${guestId}_booking-2`, booking({ id: 'booking-2' }));
  await assertFails(updateDoc(
    doc(guest, `bookings/${guestId}_booking-2`),
    { totalPrice: 1 },
  ));
});

test('a guest may cancel a confirmed booking only more than 24 hours before check-in', async () => {
  const guest = env.authenticatedContext(guestId).firestore();
  const futureRef = doc(guest, `bookings/${guestId}_booking-future`);
  await seed(`bookings/${guestId}_booking-future`, booking({
    id: 'booking-future',
    status: 'confirmed',
    checkInEpochMillis: Date.now() + 48 * 60 * 60 * 1000,
  }));
  await assertSucceeds(updateDoc(futureRef, { status: 'cancelled' }));

  const closeRef = doc(guest, `bookings/${guestId}_booking-close`);
  await seed(`bookings/${guestId}_booking-close`, booking({
    id: 'booking-close',
    status: 'confirmed',
    checkInEpochMillis: Date.now() + 23 * 60 * 60 * 1000,
  }));
  await assertFails(updateDoc(closeRef, { status: 'cancelled' }));

  const legacyRef = doc(guest, `bookings/${guestId}_booking-legacy`);
  const legacy = booking({ id: 'booking-legacy', status: 'confirmed' });
  delete legacy.checkInEpochMillis;
  await seed(`bookings/${guestId}_booking-legacy`, legacy);
  await assertFails(updateDoc(legacyRef, { status: 'cancelled' }));
});

test('hosts can manage shared bookings, homestays, rooms, finance, and staff', async () => {
  const host = env.authenticatedContext(hostId).firestore();
  await seed(`users/${hostId}`, {
    uid: hostId,
    email: 'host@example.test',
    role: 'host',
  });
  await seed(`bookings/${guestId}_booking-1`, booking());

  await assertSucceeds(getDoc(doc(host, `bookings/${guestId}_booking-1`)));
  await assertSucceeds(updateDoc(doc(host, `bookings/${guestId}_booking-1`), {
    status: 'confirmed',
  }));
  await assertSucceeds(setDoc(doc(host, 'homestays/stay-2'), { name: 'New stay' }));
  await assertSucceeds(setDoc(doc(host, 'rooms/room-1'), { homestayId: 'stay-2' }));
  await assertSucceeds(setDoc(doc(host, 'financeEntries/entry-2'), { amount: 200 }));
  await assertSucceeds(setDoc(doc(host, 'staffMembers/staff-2'), { name: 'New staff' }));
  await assertSucceeds(setDoc(doc(host, 'staffShifts/shift-2'), { staffId: 'staff-2' }));
});

test('a guest can review only their checked-out booking with a valid rating', async () => {
  const guest = env.authenticatedContext(guestId).firestore();
  await seed(`bookings/${guestId}_booking-1`, booking({ status: 'checkedOut' }));
  await seed(`bookings/${guestId}_booking-pending`, booking({
    id: 'booking-pending',
    status: 'pending',
  }));

  await assertSucceeds(setDoc(doc(guest, `reviews/${guestId}_booking-1`), review()));
  await assertFails(setDoc(doc(guest, `reviews/${guestId}_booking-pending`), review({
    bookingId: 'booking-pending',
  })));
  await assertFails(setDoc(doc(guest, `reviews/${guestId}_bad-rating`), review({
    bookingId: 'bad-rating',
    rating: 6,
  })));
  await assertFails(setDoc(doc(guest, `${'reviews'}/${otherGuestId}_booking-1`), review({
    bookingId: 'booking-1',
    guestId: otherGuestId,
  })));
});

test('Firebase Auth and Firestore emulator complete a guest-to-host booking flow', async () => {
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
  const guestApp = initializeApp({
    apiKey: 'fake-api-key',
    authDomain: 'localhost',
    projectId: 'demo-hhl-stay-rules',
    appId: `guest-${suffix}`,
  }, `guest-${suffix}`);
  const hostApp = initializeApp({
    apiKey: 'fake-api-key',
    authDomain: 'localhost',
    projectId: 'demo-hhl-stay-rules',
    appId: `host-${suffix}`,
  }, `host-${suffix}`);
  const guestAuth = initializeAuth(guestApp, { persistence: inMemoryPersistence });
  const hostAuth = initializeAuth(hostApp, { persistence: inMemoryPersistence });
  connectAuthEmulator(guestAuth, 'http://127.0.0.1:9099', {
    disableWarnings: true,
  });
  connectAuthEmulator(hostAuth, 'http://127.0.0.1:9099', {
    disableWarnings: true,
  });
  const guestDb = getFirestore(guestApp);
  const hostDb = getFirestore(hostApp);
  connectFirestoreEmulator(guestDb, '127.0.0.1', 8180);
  connectFirestoreEmulator(hostDb, '127.0.0.1', 8180);

  let guestUid;
  let hostUid;
  const bookingPath = `bookings/${suffix}_booking`;
  let guestPath;
  let hostPath;
  const financePath = `financeEntries/${suffix}_expense`;
  try {
    const guest = await createUserWithEmailAndPassword(
      guestAuth,
      `guest-${suffix}@example.test`,
      'Temporary-Emulator-Pass-123!',
    );
    guestUid = guest.user.uid;
    guestPath = `users/${guestUid}`;
    await assertSucceeds(setDoc(doc(guestDb, `users/${guestUid}`), {
      uid: guestUid,
      email: guest.user.email,
      displayName: 'Emulator guest',
      role: 'guest',
    }));

    const host = await createUserWithEmailAndPassword(
      hostAuth,
      `host-${suffix}@example.test`,
      'Temporary-Emulator-Pass-123!',
    );
    hostUid = host.user.uid;
    hostPath = `users/${hostUid}`;
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `users/${hostUid}`), {
        uid: hostUid,
        email: host.user.email,
        displayName: 'Emulator host',
        role: 'host',
      });
    });

    await assertSucceeds(setDoc(doc(guestDb, bookingPath), {
      id: `${suffix}_booking`,
      guestId: guestUid,
      hostId: hostUid,
      homestayId: 'emulator-stay',
      status: 'pending',
      guests: 2,
      payments: [],
      checkInEpochMillis: Date.now() + 10 * 24 * 60 * 60 * 1000,
    }));
    await assertSucceeds(setDoc(doc(hostDb, financePath), {
      id: `${suffix}_expense`,
      title: 'Emulator test expense',
      amount: 100,
    }));
    await assertSucceeds(updateDoc(doc(hostDb, bookingPath), {
      status: 'confirmed',
    }));
    assert.equal((await getDocs(collection(hostDb, 'bookings'))).size > 0, true);
    assert.equal((await getDoc(doc(guestDb, bookingPath))).data().status, 'confirmed');
    await assert.rejects(getDoc(doc(guestDb, financePath)));
    await assert.rejects(updateDoc(doc(guestDb, `users/${guestUid}`), {
      role: 'host',
    }));
  } finally {
    await env.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      const cleanup = [
        deleteDoc(doc(adminDb, bookingPath)),
        deleteDoc(doc(adminDb, financePath)),
      ];
      if (guestPath) cleanup.push(deleteDoc(doc(adminDb, guestPath)));
      if (hostPath) cleanup.push(deleteDoc(doc(adminDb, hostPath)));
      await Promise.all(cleanup);
    });
    if (guestAuth.currentUser) await deleteUser(guestAuth.currentUser);
    if (hostAuth.currentUser) await deleteUser(hostAuth.currentUser);
    await deleteApp(guestApp);
    await deleteApp(hostApp);
  }
});
