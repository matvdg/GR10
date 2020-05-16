//
//  PoiDetail.swift
//  Cagateille
//
//  Created by Mathieu Vandeginste on 08/05/2020.
//  Copyright © 2020 Mathieu Vandeginste. All rights reserved.
//

import SwiftUI

struct PoiDetail: View {
  
  @Binding var clockwise: Bool
  
  var poi: Poi
  
  var body: some View {
    VStack {
      
      NavigationLink(destination: MapViewContainer(poiCoordinate: poi.coordinate)) {
        
        MapView(poiCoordinate: poi.coordinate)
          .frame(height: 300)
      }
      
      CircleImage(id: poi.id)
        .offset(x: 0, y: -130)
        .padding(.bottom, -130)
      
      VStack(alignment: .leading, spacing: 20.0) {
        
        Text(poi.name)
          .font(.title)
          .fontWeight(.heavy)
          
        
        HStack(alignment: .center, spacing: 20.0) {
                    
          VStack(alignment: .leading, spacing: 8) {
                        
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 4) {
                Text("DurationEstimated".localized)
                  .foregroundColor(Color("grgray"))
                Text(poi.estimations.duration).fontWeight(.bold)
              }
            }
            
          }
                    
          Divider()
                    
          VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Altitude".localized)
                  .foregroundColor(Color("grgray"))
                Text(poi.altitudeInMeters).fontWeight(.bold)
              }
            }
                        
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Distance".localized)
                  .foregroundColor(Color("grgray"))
                Text(poi.estimations.distance).fontWeight(.bold)
              }
            }
            
          }
          
          Divider()
          
          VStack(alignment: .leading, spacing: 8) {
            
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 4) {
                Text("PositiveElevation".localized)
                  .foregroundColor(Color("grgray"))
                Text(poi.estimations.positiveElevation).fontWeight(.bold)
              }
            }
                        
            VStack(alignment: .leading, spacing: 8) {
              VStack(alignment: .leading, spacing: 4) {
                Text("NegativeElevation".localized)
                  .foregroundColor(Color("grgray"))
                Text(poi.estimations.negativeElevation).fontWeight(.bold)
              }
            }

          }
          
        }
        .font(/*@START_MENU_TOKEN@*/.subheadline/*@END_MENU_TOKEN@*/)
        .frame(maxHeight: 100)
        
        ScrollView {
          Text(poi.description ?? "")
            .font(.body)
            .foregroundColor(.text)
            .padding(.trailing, 8)
        }
        
      }
      .padding()
      
      Spacer()
    }
    .navigationBarTitle(Text(poi.name))
  }
}

// MARK: Previews
struct PoiDetail_Previews: PreviewProvider {
  @State static var clockwise = true
  static var previews: some View {
    PoiDetail(clockwise: $clockwise, poi: pois[7])
      .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
      .previewDisplayName("iPhone SE")
      .environment(\.colorScheme, .light)
  }
}
