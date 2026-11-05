import { LightningElement, api, wire } from 'lwc';
import getTimeZoneForRecord from '@salesforce/apex/RegionTimeZoneController.getTimeZoneForRecord';

const DEFAULT_TIME_ZONE = 'America/New_York';

const TIME_ZONE_OPTIONS = [
    { label: 'Appalachia', value: 'America/New_York' },
    { label: 'TX/Bakken', value: 'America/Chicago' },
    { label: 'Rockies', value: 'America/Denver' },
    { label: 'UAE', value: 'Asia/Dubai' },
    { label: 'KSA', value: 'Asia/Riyadh' }
];

// Intl has no short names for these zones and renders "GMT+4"/"GMT+3" instead.
const ABBREVIATION_OVERRIDES = {
    'Asia/Dubai': 'GST',
    'Asia/Riyadh': 'AST'
};

export default class RegionClock extends LightningElement {
    @api recordId;

    timeZone = DEFAULT_TIME_ZONE;
    now = new Date();
    region;
    userSelected = false;
    errorMessage;
    timer;

    get options() {
        return TIME_ZONE_OPTIONS.map((option) => ({
            ...option,
            id: `tz-${option.value}`,
            checked: option.value === this.timeZone
        }));
    }

    @wire(getTimeZoneForRecord, { recordId: '$recordId' })
    wiredTimeZone({ data, error }) {
        if (data) {
            this.region = data.region;
            if (!this.userSelected) {
                this.timeZone = data.timeZone;
            }
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = error.body?.message ?? 'Unable to load the region time zone.';
        }
    }

    connectedCallback() {
        this.timer = setInterval(() => {
            this.now = new Date();
        }, 1000);
    }

    disconnectedCallback() {
        clearInterval(this.timer);
    }

    handleTimeZoneChange(event) {
        this.userSelected = true;
        this.timeZone = event.target.value;
    }

    get formattedTime() {
        return new Intl.DateTimeFormat('en-US', {
            timeZone: this.timeZone,
            hour: 'numeric',
            minute: '2-digit'
        }).format(this.now);
    }

    get formattedDate() {
        return new Intl.DateTimeFormat('en-US', {
            timeZone: this.timeZone,
            weekday: 'long',
            month: 'long',
            day: 'numeric',
            year: 'numeric'
        }).format(this.now);
    }

    get timeZoneAbbreviation() {
        if (ABBREVIATION_OVERRIDES[this.timeZone]) {
            return ABBREVIATION_OVERRIDES[this.timeZone];
        }
        const part = new Intl.DateTimeFormat('en-US', {
            timeZone: this.timeZone,
            timeZoneName: 'short'
        })
            .formatToParts(this.now)
            .find((p) => p.type === 'timeZoneName');
        return part ? part.value : '';
    }
}