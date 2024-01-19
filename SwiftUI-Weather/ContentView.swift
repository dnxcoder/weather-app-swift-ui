//
//  ContentView.swift
//  SwiftUI-Weather
//
//  Created by Denis Coder on 1/12/24.
//

import SwiftUI

struct Values: Decodable {
    let temperatureAvg: Double?
    let temperatureMax: Double?
    let temperatureMin: Double?
}

struct MinuteData: Decodable {
    let time: String?
    let values: Values?
}

struct HourlyData: Decodable {
    let time: String?
    let values: Values?
}

struct DailyData: Decodable {
    let time: String
    let values: Values
}

struct Location: Decodable {
    let lat: Double?
    let lon: Double?
    let name: String?
    let type: String?
}

struct Timelines: Decodable {
    let minutely: [MinuteData]
    let hourly: [HourlyData]
    let daily: [DailyData]
}

struct WeatherData: Decodable {
    let timelines: Timelines
    let location: Location
}

struct WeatherState {
    var day:String
    var maxTemp: Int
    var minTemp: Int
    var avgTemp: Int
}


struct ContentView: View {
    
    @State private var isNight = false;
    @State private var weatherArray: [WeatherState] = [];
    @State private var showModal = false;
    
    func changeCity() async throws -> Void {
        
        let myUrl = "https://api.tomorrow.io/v4/weather/forecast?location=Centralia&apikey=n6d1Z5v6i6Gxs8CpH7qZ38mdcKDnUh54";
        
        let url = URL(string: myUrl);
        
        //url is an optional variable
        // this way we need to unwrapped it and make sure we are taking the value from it
        
        if let unwrappedURL = url {
            
            // destructing tuplos
            let (data, _) = try await URLSession.shared.data(from: unwrappedURL);
            
            
             let jsonDecoded = try JSONDecoder().decode(WeatherData.self,from: data);
            
            
            let daysPrediction = jsonDecoded.timelines.daily;
            
            weatherArray.removeAll();
            
            for (index,days) in daysPrediction.enumerated() {
                
                var intAvgTemp=0;
                
                if let unwrapedAvgTempDouble = days.values.temperatureAvg {
                    intAvgTemp = Int(unwrapedAvgTempDouble)
                }else {
                    print("no value for max temp")
                }
                
                if(index<5){
                    weatherArray.append(WeatherState(day: "\(convertDate(dateString: days.time))", maxTemp: 0, minTemp: 0, avgTemp: intAvgTemp));
                }
              
            }
            
        }else {
            
            
        }
        
    }
    
    func convertDate(dateString:String) -> String{
        
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ";
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = dateFormatter.date(from: dateString) {
            _ = Calendar.current.component(.weekday, from: date)
            _ = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
            
            let calendar = Calendar.current
                let weekday = calendar.component(.weekday, from: date)
                let abbreviatedWeekday = calendar.shortWeekdaySymbols[weekday - 1]
            
            return abbreviatedWeekday;
        } else {
            return "";
        }
    }

    
    
    var body: some View {
        ZStack{
            BackgroundView(isNight: $isNight).onAppear{
                Task {
                    do {
                       try await changeCity();
                    }catch {
                        print("Erro ao carregar dados: \(error)")
                    }
                }
            }
            VStack{
                VStack {
                    CityName(city: "Saint Louis", state: "IL")
                }
                MainWeatherStatusView(
                    iconName: isNight ? "moon.stars.fill" : "cloud.sun.fill", temperature:76)
                
                HStack(spacing:22){

                    ForEach(weatherArray.indices, id: \.self){ index in
                        
                        WeatherDayView(dayOfWeek: self.weatherArray[index].day, imageName: "wind.snow", temperature: self.weatherArray[index].avgTemp)
                    }
                }.padding(.top,40)
                Spacer()
                
                Button {
                    isNight.toggle();
                    showModal.toggle();
                    
                    Task {
                        do {
                            try await changeCity();
                        } catch {
                            print("Error occurred: \(error)")
                        }
                    }
                } label: {
                    WeatherButton(title: "Change Location", textColor: Color.blue, backgroundColor: Color.white)
                } .sheet(isPresented: $showModal) {
                    // Conteúdo do seu modal
                    ModalView(showModal: $showModal)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}

struct WeatherDayView: View {
    
    var dayOfWeek: String
    var imageName: String
    var temperature:Int
    
    var body: some View {
        VStack{
            Text(dayOfWeek)
                .foregroundColor(Color.white)
                .font(.system(size: 19,weight: Font.Weight.bold))
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
            Text(String(temperature))
                .font(.system(size: 24, weight: Font.Weight.bold))
                .foregroundColor(Color.white)
            
        }
    }
}

struct BackgroundView: View {
    
    @Binding var isNight: Bool
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [isNight ? Color.black : Color.blue, isNight ? Color.gray : Color.white]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        .ignoresSafeArea(.all)
    }
}

struct CityName: View {
    
    var city: String
    var state: String
    
    var body: some View {
        Text(city + ", " + state)
            .font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(.white)
            .padding()
        
    }
    
}

struct MainWeatherStatusView: View {
    
    var iconName: String
    var temperature: Int
    
    var body: some View {
        VStack(spacing:0) {
            Image(systemName: iconName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
            
            Text("\(temperature)°")
                .font(.system(size: 70, weight: Font.Weight.medium))
                .foregroundColor(Color.white)
        }
    }
}

struct ModalView: View {
    
    @Binding var showModal: Bool;
    
    var body: some View {
        Text("MODALZINHO").padding();
        Button{
            showModal.toggle();
        } label: {
            Text("Close")
        }
    }
}

