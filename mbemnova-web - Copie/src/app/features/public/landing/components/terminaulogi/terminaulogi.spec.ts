import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Terminaulogi } from './terminaulogi';

describe('Terminaulogi', () => {
  let component: Terminaulogi;
  let fixture: ComponentFixture<Terminaulogi>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Terminaulogi],
    }).compileComponents();

    fixture = TestBed.createComponent(Terminaulogi);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
