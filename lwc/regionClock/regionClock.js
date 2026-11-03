import { LightningElement, api, wire } from 'lwc';
import getTimeZoneForRecord from '@salesforce/apex/RegionTimeZoneController.getTimeZoneForRecord';

const DEFAULT_TIME_ZONE = 'America/New_York';

const TIME_ZONE_OPTIONS = [
    { label: 'Eastern Time (EST/EDT)', value: 'America/New_York' },
    { label: 'Central Time (CST/CDT)', value: 'America/Chicago' },
    { label: 'Mountain Time (MST/MDT)', value: 'America/Denver' },
    { label: 'UAE - Gulf Standard Time (GST)', value: 'Asia/Dubai' },
    { label: 'Saudi Arabia - Arabia Standard Time (AST)', value: 'Asia/Riyadh' }
];

export default class RegionClock extends LightningElement {
    @api recordId;

    timeZone = DEFAULT_TIME_ZONE;
    now = new Date();
    region;
    userSelected = false;
    errorMessage;
    timer;

    options = TIME_ZONE_OPTIONS;

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
        this.timeZone = event.detail.value;
    }

    get formattedTime() {
        return new Intl.DateTimeFormat('en-US', {
            timeZone: this.timeZone,
            hour: 'numeric',
            minute: '2-digit',
            second: '2-digit'
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
        const part = new Intl.DateTimeFormat('en-US', {
            timeZone: this.timeZone,
            timeZoneName: 'short'
        })
            .formatToParts(this.now)
            .find((p) => p.type === 'timeZoneName');
        return part ? part.value : '';
    }
}