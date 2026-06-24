import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Foramtions } from './foramtions';

describe('Foramtions', () => {
  let component: Foramtions;
  let fixture: ComponentFixture<Foramtions>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Foramtions],
    }).compileComponents();

    fixture = TestBed.createComponent(Foramtions);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
