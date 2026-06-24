import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AppelAction } from './appel-action';

describe('AppelAction', () => {
  let component: AppelAction;
  let fixture: ComponentFixture<AppelAction>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppelAction],
    }).compileComponents();

    fixture = TestBed.createComponent(AppelAction);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
