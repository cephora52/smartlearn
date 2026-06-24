import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Blockticket } from './blockticket';

describe('Blockticket', () => {
  let component: Blockticket;
  let fixture: ComponentFixture<Blockticket>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Blockticket],
    }).compileComponents();

    fixture = TestBed.createComponent(Blockticket);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
