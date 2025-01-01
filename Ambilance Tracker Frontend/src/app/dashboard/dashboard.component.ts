import { Component, OnInit, OnDestroy } from '@angular/core';
import * as mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { HospitalService } from '../services/hospital.service';
import { Hospital } from '../models/hospital.model';
import { WebsocketService } from '../services/websocket.service';
import { AmbulanceService } from '../services/ambulance.service';
import { Ambulance } from '../models/ambulance.model';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css'],
})
export class DashboardComponent implements OnInit, OnDestroy {
  map!: mapboxgl.Map;
  availableAmbulances: number = 8;
  availableHospitals: number = 5;
  activeCases: number = 3;
  hospitals: Hospital[] = [];
  ambulances: Ambulance[] = [];
  ambulanceMarkers: { [key: string]: mapboxgl.Marker } = {};
  private locationSubscription?: Subscription;

  constructor(
    private hospitalService: HospitalService,
    private ambulanceService: AmbulanceService,
    private websocketService: WebsocketService
  ) {}

  ngOnInit(): void {
    this.initializeMap();
    this.loadHospitalData();
    this.loadAmbulances();
    this.subscribeToLocationUpdates();
  }

  ngOnDestroy(): void {
    if (this.locationSubscription) {
      this.locationSubscription.unsubscribe();
    }
    // Remove all markers
    Object.values(this.ambulanceMarkers).forEach(marker => marker.remove());
  }

  initializeMap(): void {
    this.map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/yacinemansour/cm4u3ppqk003d01sa0bch87jn',
      center: [-7.9811, 31.6295],
      zoom: 12,
      accessToken: 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
    });
  }

  loadAmbulances(): void {
    this.ambulanceService.getAllAmbulances().subscribe(ambulances => {
      this.ambulances = ambulances;
      this.updateAvailableAmbulances();
      this.addAmbulanceMarkers();
    });
  }

  private updateAvailableAmbulances(): void {
    this.availableAmbulances = this.ambulances.filter(a => a.available).length;
  }

  private subscribeToLocationUpdates(): void {
    this.locationSubscription = this.websocketService.getAmbulanceLocations().subscribe(
      locations => {
        locations.forEach(location => {
          const ambulanceId = location.ambulanceId;
          const marker = this.ambulanceMarkers[ambulanceId];
          
          if (marker) {
            // Update marker position with smooth animation
            marker.setLngLat([location.longitude, location.latitude]);
          }

          // Update ambulance data
          const ambulance = this.ambulances.find(a => a.id === Number(ambulanceId));
          if (ambulance) {
            ambulance.latitude = location.latitude;
            ambulance.longitude = location.longitude;
          }
        });
      },
      error => {
        console.error('Error receiving ambulance locations:', error);
      }
    );
  }

  private addAmbulanceMarkers(): void {
    this.ambulances.forEach(ambulance => {
      // Create marker element
      const el = document.createElement('div');
      el.className = 'ambulance-marker';
      el.style.backgroundImage = 'url(/icons/ambulance.png)';
      el.style.width = '32px';
      el.style.height = '32px';
      el.style.backgroundSize = 'contain';
      el.style.cursor = 'pointer';

      // Add popup
      const popup = new mapboxgl.Popup({ offset: 25 })
        .setHTML(`
          <div class="ambulance-popup">
            <h3>Ambulance ${ambulance.id}</h3>
            <p>Driver: ${ambulance.driverName}</p>
            <p>Status: ${ambulance.available ? 'Available' : 'Busy'}</p>
          </div>
        `);

      // Create and store the marker
      const marker = new mapboxgl.Marker(el)
        .setLngLat([ambulance.longitude, ambulance.latitude])
        .setPopup(popup)
        .addTo(this.map);

      this.ambulanceMarkers[ambulance.id] = marker;
    });
  }

  loadHospitalData(): void {
    this.hospitalService.getAllHospitals().subscribe((data) => {
      this.hospitals = data;
      this.availableHospitals = data.length;
      this.addHospitalMarkers();
    });
  }

  addHospitalMarkers(): void {
    for (const feature of this.hospitals) {
      const el = document.createElement('div');
      el.className = 'hospital-marker';
      el.style.backgroundImage = 'url(/icons/hospital.png)';
      el.style.width = '32px';
      el.style.height = '32px';
      el.style.backgroundSize = 'contain';

      // Add popup for hospitals
      const popup = new mapboxgl.Popup({ offset: 25 })
        .setHTML(`
          <div class="hospital-popup">
            <h3>${feature.name}</h3>
            <p>${feature.address}</p>
          </div>
        `);

      new mapboxgl.Marker(el)
        .setLngLat([feature.longitude, feature.latitude])
        .setPopup(popup)
        .addTo(this.map);
    }
  }
}
