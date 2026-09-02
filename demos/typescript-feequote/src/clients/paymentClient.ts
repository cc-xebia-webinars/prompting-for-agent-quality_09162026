// Payment gateway client. The real gateway integration lives behind the
// PaymentGateway interface; the stub below is what local runs and tests use.
import type { Transfer } from '../models.js';

export interface SubmissionReceipt {
  readonly transferId: string;
  readonly reference: string;
  readonly acceptedAt: string;
}

/** The payment gateway. */
export interface PaymentGateway {
  submit(transfer: Transfer, idempotencyKey: string): Promise<SubmissionReceipt>;
}

/** The gateway did not accept the submission. */
export class GatewayUnavailableError extends Error {
  constructor(message = 'payment gateway unavailable') {
    super(message);
    this.name = 'GatewayUnavailableError';
  }
}

/** The gateway did not respond in time. */
export class GatewayTimeoutError extends GatewayUnavailableError {
  constructor(message = 'payment gateway timed out') {
    super(message);
    this.name = 'GatewayTimeoutError';
  }
}

/** The gateway declined the transfer. */
export class GatewayDeclinedError extends GatewayUnavailableError {
  constructor(message = 'payment gateway declined the transfer') {
    super(message);
    this.name = 'GatewayDeclinedError';
  }
}

export interface StubPaymentClientOptions {
  /** Clock override so receipts are deterministic in tests. */
  readonly now?: () => Date;
  /** Number of submissions to reject with GatewayUnavailableError before accepting. */
  readonly failuresBeforeSuccess?: number;
}

/**
 * In-memory stand-in for the gateway. Records what was submitted so callers can
 * inspect it, and can be told to fail a few times first to exercise error paths.
 */
export class StubPaymentClient implements PaymentGateway {
  readonly submitted: Transfer[] = [];
  private sequence = 0;
  private remainingFailures: number;
  private readonly now: () => Date;
  private readonly receiptsByKey = new Map<string, SubmissionReceipt>();

  constructor(options: StubPaymentClientOptions = {}) {
    this.now = options.now ?? (() => new Date());
    this.remainingFailures = options.failuresBeforeSuccess ?? 0;
  }

  async submit(transfer: Transfer, idempotencyKey: string): Promise<SubmissionReceipt> {
    if (this.remainingFailures > 0) {
      this.remainingFailures -= 1;
      throw new GatewayUnavailableError();
    }
    const existing = this.receiptsByKey.get(idempotencyKey);
    if (existing !== undefined) {
      return existing;
    }
    this.sequence += 1;
    this.submitted.push(transfer);
    const receipt: SubmissionReceipt = {
      transferId: transfer.id,
      reference: `STUB-${String(this.sequence).padStart(6, '0')}`,
      acceptedAt: this.now().toISOString(),
    };
    this.receiptsByKey.set(idempotencyKey, receipt);
    return receipt;
  }
}
